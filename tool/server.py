import http.server
import json
import os
import tempfile
import zipfile
from urllib.parse import urlparse, parse_qs

HOST = '0.0.0.0'
PORT = 18730

# 客户端访问地址（生成下载 URL 用）。设为 None 则自动获取局域网 IP。
SERVER_HOST = None


def _get_lan_ip():
    """获取本机局域网 IP 地址。"""
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # 不需要真正发包，只是让 OS 选一个到达目标的网卡
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except Exception:
        return '127.0.0.1'
    finally:
        s.close()

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PACKAGES_DIR = os.path.join(SCRIPT_DIR, 'packages')

# Dynamic package registry: bisName -> zip_file
PACKAGES = {}
# Version registry: bisName -> version
VERSIONS = {}
# 客户端可访问的主机地址（启动时自动检测）
effective_host = '127.0.0.1'


def _scan_packages():
    """Scan packages directory and load package info from .offweb.json"""
    global PACKAGES, VERSIONS
    PACKAGES.clear()
    VERSIONS.clear()

    if not os.path.exists(PACKAGES_DIR):
        print(f'[警告] packages 目录不存在: {PACKAGES_DIR}')
        return

    for filename in os.listdir(PACKAGES_DIR):
        if not filename.endswith('.zip'):
            continue

        zip_path = os.path.join(PACKAGES_DIR, filename)
        bis_name = filename[:-4]  # Remove .zip extension
        extract_dir = None

        try:
            with tempfile.TemporaryDirectory() as tmpdir:
                with zipfile.ZipFile(zip_path, 'r') as zf:
                    zf.extractall(tmpdir)
                    extract_dir = os.path.join(tmpdir, bis_name)

                    offweb_path = os.path.join(tmpdir, '.offweb.json')
                    if os.path.exists(offweb_path):
                        with open(offweb_path, 'r') as f:
                            info = json.load(f)
                            bis_name = info.get('bisName', bis_name)
                            version = info.get('version', 'v1')
                    else:
                        version = 'v1'
                        print(f'[警告] {filename} 缺少 .offweb.json，使用默认版本 v1')

            PACKAGES[bis_name] = filename
            VERSIONS[bis_name] = version
            print(f'[加载] {bis_name} ({version}): {filename}')

        except Exception as e:
            print(f'[错误] 处理 {filename} 失败: {e}')


def _get_zip_path(bis_name):
    zip_file = PACKAGES.get(bis_name)
    if zip_file:
        path = os.path.join(PACKAGES_DIR, zip_file)
        if os.path.exists(path):
            return path
    return None


DEMO_HTML_PATH = os.path.join(SCRIPT_DIR, 'demo.html')
UPLOAD_HTML_PATH = os.path.join(SCRIPT_DIR, 'upload.html')

def _load_html(path):
    """从文件加载 HTML 内容。"""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f'[错误] 文件未找到: {path}')
        return f'<html><body><h1>File not found</h1></body></html>'
    except Exception as e:
        print(f'[错误] 读取文件失败: {e}')
        return f'<html><body><h1>Error loading file</h1></body></html>'

def _load_demo_html():
    return _load_html(DEMO_HTML_PATH)

def _load_upload_html():
    return _load_html(UPLOAD_HTML_PATH)

DEMO_HTML = _load_demo_html()
UPLOAD_HTML = _load_upload_html()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        u = urlparse(self.path)

        if u.path == '/upload':
            content_type = self.headers.get('Content-Type', '')
            print(f'[Upload] Content-Type: {content_type}')

            if 'multipart/form-data' not in content_type:
                print('[Upload] 不是 multipart/form-data 格式')
                body = json.dumps({'error': '需要 multipart/form-data 格式'})
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(body.encode())
                return

            try:
                content_length = int(self.headers.get('Content-Length', 0))
                print(f'[Upload] Content-Length: {content_length}')
                form_data = self.rfile.read(content_length)
                print(f'[Upload] 读取到数据长度: {len(form_data)}')

                if 'boundary=' not in content_type:
                    print('[Upload] boundary 未找到')
                    body = json.dumps({'error': 'boundary 未找到'})
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(body.encode())
                    return

                boundary = content_type.split('boundary=')[-1].strip()
                if boundary.startswith('"') and boundary.endswith('"'):
                    boundary = boundary[1:-1]
                boundary = boundary.encode()
                print(f'[Upload] boundary: {boundary}')

                parts = form_data.split(b'--' + boundary)
                print(f'[Upload] 分割后 parts 数量: {len(parts)}')

                zip_data = None
                original_name = None

                for i, part in enumerate(parts):
                    if b'filename=' in part:
                        header_end = part.index(b'\r\n\r\n')
                        header = part[:header_end].decode('utf-8', errors='ignore')
                        zip_data = part[header_end + 4:]
                        if zip_data.endswith(b'\r\n'):
                            zip_data = zip_data[:-2]

                        import re
                        match = re.search(r'filename="([^"]+)"', header)
                        if match:
                            original_name = match.group(1)
                        break

                print(f'[Upload] 文件名: {original_name}, zip_data 长度: {len(zip_data) if zip_data else 0}')

                if zip_data is None or len(zip_data) == 0:
                    print('[Upload] 未找到 zip 数据')
                    body = json.dumps({'error': '未找到 zip 文件'})
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(body.encode())
                    return

                if not original_name or not original_name.endswith('.zip'):
                    print(f'[Upload] 不是 zip 文件: {original_name}')
                    body = json.dumps({'error': '只支持 .zip 文件'})
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(body.encode())
                    return

                bis_name = original_name[:-4]
                print(f'[Upload] 处理 bisName: {bis_name}')

                with tempfile.TemporaryDirectory() as tmpdir:
                    zip_path = os.path.join(tmpdir, original_name)
                    with open(zip_path, 'wb') as f:
                        f.write(zip_data)

                    # 检查 zip 内部结构
                    with zipfile.ZipFile(zip_path, 'r') as zf:
                        names = zf.namelist()

                    # 检查第一层是否有目录
                    has_root_folder = False
                    root_folder_name = None
                    for name in names:
                        parts = name.split('/')
                        if len(parts) > 1 and parts[0]:
                            has_root_folder = True
                            root_folder_name = parts[0]
                            break

                    if has_root_folder:
                        # zip 内部已有根文件夹，直接解压
                        extract_dir = os.path.join(tmpdir, root_folder_name)
                        with zipfile.ZipFile(zip_path, 'r') as zf:
                            zf.extractall(tmpdir)
                        print(f'[Upload] 使用 zip 内已有的根文件夹: {root_folder_name}/')
                    else:
                        # zip 内部没有根文件夹，需要创建 bis_name/ 文件夹
                        extract_dir = os.path.join(tmpdir, bis_name)
                        os.makedirs(extract_dir)
                        with zipfile.ZipFile(zip_path, 'r') as zf:
                            for name in names:
                                # 解压到 bis_name 子文件夹
                                target_path = os.path.join(extract_dir, name)
                                if name.endswith('/'):
                                    os.makedirs(target_path, exist_ok=True)
                                else:
                                    os.makedirs(os.path.dirname(target_path), exist_ok=True)
                                    with open(target_path, 'wb') as out_f:
                                        out_f.write(zf.read(name))
                        print(f'[Upload] 创建了 {bis_name}/ 文件夹')

                    offweb = {
                        'bisName': bis_name,
                        'version': 'v1.0.0',
                    }
                    offweb_path = os.path.join(extract_dir, '.offweb.json')
                    with open(offweb_path, 'w', encoding='utf-8') as f:
                        json.dump(offweb, f, ensure_ascii=False, indent=2)
                    print(f'[Upload] 写入 .offweb.json 成功')

                    output_zip = os.path.join(tmpdir, original_name)
                    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
                        for root, dirs, files in os.walk(extract_dir):
                            for file in files:
                                file_path = os.path.join(root, file)
                                arcname = os.path.relpath(file_path, extract_dir)
                                zf.write(file_path, arcname)
                    print(f'[Upload] 重新打包成功')

                    os.makedirs(PACKAGES_DIR, exist_ok=True)
                    final_path = os.path.join(PACKAGES_DIR, original_name)
                    import shutil
                    # 删除已存在的同名 zip
                    if os.path.exists(final_path):
                        os.remove(final_path)
                        print(f'[Upload] 已删除旧的: {final_path}')
                    shutil.copy2(output_zip, final_path)
                    print(f'[Upload] 复制到 packages 目录: {final_path}')

                    _scan_packages()

                    body = json.dumps({
                        'status': 'ok',
                        'bisName': bis_name,
                        'message': f'上传成功，已添加到 packages 目录',
                    })
                    print(f'[Upload] {bis_name} 上传成功')
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(body.encode())

            except Exception as e:
                import traceback
                print(f'[Upload] 上传失败: {e}')
                traceback.print_exc()
                body = json.dumps({'error': f'上传失败: {e}'})
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(body.encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)

        if u.path == '/':
            body = json.dumps({
                'status': 'ok',
                'packages': list(PACKAGES.keys()),
                'endpoints': {
                    '/': '服务信息',
                    '/health': '健康检查',
                    '/demo': '离线包演示页面',
                    '/upload-page': '离线包上传页面',
                    '/offweb?bisName=xxx&offlineZipVer=xxx': '查询离线包更新',
                    '/package?bisName=xxx': '下载离线包 zip',
                    '/upload': '上传离线包 zip',
                },
            })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(body.encode())

        elif u.path == '/offweb':
            bis_name = q.get('bisName', [''])[0]
            offline_zip_ver = q.get('offlineZipVer', ['0'])[0]

            print(f'[Offweb Query] bisName={bis_name}, clientVersion={offline_zip_ver}')

            if bis_name not in PACKAGES:
                body = json.dumps({
                    'bisName': bis_name,
                    'result': -1,
                    'version': '0',
                    'url': '',
                    'refreshMode': 0,
                })
            else:
                server_version = VERSIONS.get(bis_name, 'v1')
                if offline_zip_ver == '0' or offline_zip_ver != server_version:
                    zip_path = _get_zip_path(bis_name)
                    if zip_path:
                        download_url = f'http://{effective_host}:{PORT}/package?bisName={bis_name}'
                    else:
                        download_url = ''
                    body = json.dumps({
                        'bisName': bis_name,
                        'result': 1,
                        'version': server_version,
                        'url': download_url,
                        'refreshMode': 0,
                    })
                else:
                    body = json.dumps({
                        'bisName': bis_name,
                        'result': 0,
                        'version': offline_zip_ver,
                        'url': '',
                        'refreshMode': 0,
                    })

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(body.encode())

        elif u.path == '/package':
            bis = q.get('bisName', [''])[0]
            zip_path = _get_zip_path(bis)
            if zip_path is None:
                body = json.dumps({'error': f'No package for bisName: {bis}'})
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(body.encode())
                return

            self.send_response(200)
            self.send_header('Content-Type', 'application/zip')
            self.send_header('Content-Length', str(os.path.getsize(zip_path)))
            self.end_headers()
            with open(zip_path, 'rb') as f:
                self.wfile.write(f.read())

        elif u.path == '/demo':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(DEMO_HTML.encode())

        elif u.path == '/upload-page':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(UPLOAD_HTML.encode())

        elif u.path == '/health':
            body = json.dumps({
                'status': 'ok',
                'port': PORT,
                'packages': VERSIONS,
            })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(body.encode())

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')

    def log_message(self, format, *args):
        print(f'[{self.address_string()}] {format % args}')


if __name__ == '__main__':
    import subprocess

    # 扫描并加载所有离线包
    print(f'扫描 packages 目录: {PACKAGES_DIR}')
    _scan_packages()

    if not PACKAGES:
        print('[警告] 未发现任何离线包！')

    # 关闭占用端口的进程
    try:
        result = subprocess.run(
            ['lsof', '-ti', f':{PORT}'],
            capture_output=True, text=True
        )
        if result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                try:
                    subprocess.run(['kill', '-9', pid])
                    print(f'[启动] 已关闭占用端口 {PORT} 的进程: {pid}')
                except Exception as e:
                    print(f'[启动] 关闭进程 {pid} 失败: {e}')
    except Exception as e:
        print(f'[启动] 检查端口占用失败: {e}')

    import time
    time.sleep(0.5)

    effective_host = SERVER_HOST if SERVER_HOST else _get_lan_ip()

    print(f'Download server running at http://{effective_host}:{PORT}')
    print(f'Registered packages: {list(PACKAGES.keys())}')
    print(f'Endpoints:')
    print(f'  GET /                     - 服务信息')
    print(f'  GET /health               - 健康检查')
    print(f'  GET /demo                 - 离线包演示页面')
    print(f'  GET /upload-page          - 离线包上传页面')
    print(f'  GET /offweb?bisName=xxx  - 查询离线包更新')
    print(f'  GET /package?bisName=xxx  - 下载离线包 zip')
    print(f'  POST /upload             - 上传离线包 zip')

    server = http.server.HTTPServer((HOST, PORT), Handler)
    server.allow_reuse_address = True
    server.serve_forever()

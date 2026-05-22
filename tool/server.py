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


DEMO_HTML = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>离线包测试页面</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #fff;
      padding: 20px;
    }
    .container { max-width: 500px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 24px; }
    .icon { font-size: 64px; margin-bottom: 12px; }
    h1 { font-size: 24px; margin-bottom: 8px; text-shadow: 0 2px 4px rgba(0,0,0,0.2); }
    .badge {
      display: inline-block; padding: 6px 16px; border-radius: 20px;
      font-size: 12px; background: #ff9800; font-weight: 600;
    }
    .card {
      background: rgba(255,255,255,0.15); border-radius: 16px; padding: 20px;
      backdrop-filter: blur(10px); margin-bottom: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }
    .card-title {
      font-size: 16px; font-weight: 600; margin-bottom: 16px;
      padding-bottom: 12px; border-bottom: 1px solid rgba(255,255,255,0.2);
      display: flex; align-items: center; gap: 8px;
    }
    .card-title span { font-size: 20px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .info-item { background: rgba(255,255,255,0.1); border-radius: 10px; padding: 12px; }
    .info-label { font-size: 11px; opacity: 0.7; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
    .info-value { font-size: 14px; font-weight: 600; word-break: break-all; }
    .status-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,0.1); }
    .status-row:last-child { border-bottom: none; }
    .status-label { font-size: 14px; opacity: 0.8; }
    .status-value { font-size: 14px; font-weight: 600; }
    .status-value.success { color: #4caf50; }
    .btn-group { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 8px; }
    .btn {
      background: rgba(255,255,255,0.2); border: none; border-radius: 10px;
      padding: 12px 16px; color: #fff; font-size: 14px; font-weight: 600;
      cursor: pointer; transition: all 0.2s;
    }
    .btn:hover { background: rgba(255,255,255,0.3); transform: translateY(-1px); }
    .btn:active { transform: translateY(0); }
    .footer { text-align: center; margin-top: 20px; font-size: 12px; opacity: 0.6; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">&#128640;</div>
      <h1>离线包测试页面</h1>
      <div class="badge">&#9733; 在线模式</div>
    </div>
    <div class="card">
      <div class="card-title"><span>&#128197;</span> 离线包信息</div>
      <div class="info-grid">
        <div class="info-item">
          <div class="info-label">业务名称</div>
          <div class="info-value" id="bisName">demo</div>
        </div>
        <div class="info-item">
          <div class="info-label">包版本</div>
          <div class="info-value" id="version">v1.0.0</div>
        </div>
        <div class="info-item">
          <div class="info-label">加载方式</div>
          <div class="info-value">本地服务</div>
        </div>
        <div class="info-item">
          <div class="info-label">资源协议</div>
          <div class="info-value">HTTP</div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-title"><span>&#9881;</span> 资源加载状态</div>
      <div class="status-row"><span class="status-label">HTML 页面</span><span class="status-value success">&#10004; 已加载</span></div>
      <div class="status-row"><span class="status-label">CSS 样式</span><span class="status-value success">&#10004; 已加载</span></div>
      <div class="status-row"><span class="status-label">JS 脚本</span><span class="status-value success">&#10004; 已加载</span></div>
      <div class="status-row"><span class="status-label">本地资源</span><span class="status-value success">&#10004; 可访问</span></div>
    </div>
    <div class="card">
      <div class="card-title"><span>&#128757;</span> 交互测试</div>
      <div class="btn-group">
        <button class="btn" onclick="testAlert()">测试弹窗</button>
        <button class="btn" onclick="testConsole()">测试控制台</button>
      </div>
    </div>
    <div class="footer">加载时间: <span id="loadTime"></span></div>
  </div>
  <script>
    document.getElementById('loadTime').textContent = new Date().toLocaleString('zh-CN');
    function testAlert() { alert('&#128079; 离线包弹窗功能正常！'); }
    function testConsole() {
      console.log('========== 离线包调试信息 ==========');
      console.log('业务名称:', document.getElementById('bisName').textContent);
      console.log('页面地址:', window.location.href);
      console.log('协议:', window.location.protocol);
      console.log('主机:', window.location.hostname);
      console.log('端口:', window.location.port || '默认');
      console.log('用户代理:', navigator.userAgent);
      console.log('在线状态:', navigator.onLine ? '在线' : '离线');
      console.log('=====================================');
      alert('&#128221; 已在控制台输出调试信息\\n请打开开发者工具查看');
    }
    console.log('&#127919; 离线包测试页面已加载');
    console.log('&#128640; 当前模式: 离线包（localhost）');
  </script>
</body>
</html>
'''


class Handler(http.server.BaseHTTPRequestHandler):
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
                    '/offweb?bisName=xxx&offlineZipVer=xxx': '查询离线包更新',
                    '/package?bisName=xxx': '下载离线包 zip',
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
    print(f'  GET /offweb?bisName=xxx  - 查询离线包更新')
    print(f'  GET /package?bisName=xxx - 下载离线包 zip')

    server = http.server.HTTPServer((HOST, PORT), Handler)
    server.allow_reuse_address = True
    server.serve_forever()

#!/usr/bin/python3

import http.server
import socketserver
import argparse


pac_path = 'proxy.pac'

parser = argparse.ArgumentParser(description='Creates HTTP server to serve PAC file. The PAC file proxies only defined hosts.', 
    usage='''servepac "*.example.com"

Example of the served PAC available at http://127.0.0.1:8000/''' + pac_path + ''':

function FindProxyForURL(url, host) {
    PROXY = "PROXY 127.0.0.1:8080"

    // host via proxy
    if (shExpMatch(host,"*.example.com")) {
        return PROXY;
    }
    // Everything else directly!
    return "DIRECT";
}''')
parser.add_argument('hosts', metavar='HOST', type=str, nargs='+',
                    help='host wildcard like *.example.com')
parser.add_argument('--proxy', type=str, default="127.0.0.1:8080",
                    help='proxy server IP:PORT')
parser.add_argument('-p', type=int, default=8000,
                    help='HTTP PAC server listening port')
parser.add_argument('-i', type=str, default='127.0.0.1',
                    help='HTTP PAC server listening ip')

args = parser.parse_args()


class PacHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'plain/text')
        self.end_headers()

        if self.path == '/' + pac_path:

            proxy_pac = '''function FindProxyForURL(url, host) {
                PROXY = "PROXY 127.0.0.1:8080"
            '''
            
            for host in args.hosts:

                proxy_pac += '''
                // host via proxy
                if (shExpMatch(host,"{}")) {{
                    return PROXY;
                }}
                '''.format(host)

            proxy_pac += '''
                // Everything else directly!
                return "DIRECT";
            }'''

            self.wfile.write(bytes(proxy_pac + '\n', "utf8"))

        else:

            self.wfile.write(bytes("OK\n", "utf8"))


handler_object = PacHttpRequestHandler


try:

    socketserver.TCPServer.allow_reuse_address = True

    with socketserver.TCPServer((args.i, args.p), handler_object) as http_server:

        print('PAC available at: http://{}:{}/{}'.format(args.i, args.p, pac_path))

        http_server.serve_forever()

except KeyboardInterrupt:

    http_server.server_close()

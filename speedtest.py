import http.server
import json
import multiprocessing as mp
import os
import sys
import time

HTTP_PORT = 80
MAX_RESULTS = 5
SPEEDTEST_TEST_INTERVAL = 5 * 60  # every 5 minutes

manager = mp.Manager()
results = manager.list()
current = manager.Value("i", 0)


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()

        while len(results) == 0:
            print("No results yet", file=sys.stderr)
            time.sleep(5)
        res = results[len(results) - 1]
        self.wfile.write(json.dumps(res).encode("utf-8"))


def serve(server_class=http.server.HTTPServer, handler_class=Handler):
    server_address = ("", HTTP_PORT)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()


def run_speedtest():
    while True:
        speedtest_results = json.loads(os.popen("speedtest -fjson").read())

        speedtest_results = {
            k: v
            for k, v in speedtest_results.items()
            if k in {"download", "upload", "ping", "timestamp"}
        }

        speedtest_results["download"] = speedtest_results["download"]["bandwidth"]
        speedtest_results["upload"] = speedtest_results["upload"]["bandwidth"]
        speedtest_results["ping"] = speedtest_results["ping"]["latency"]

        print(speedtest_results, file=sys.stderr)

        if len(results) >= MAX_RESULTS:
            results.pop(0)
        results.append(speedtest_results)

        time.sleep(SPEEDTEST_TEST_INTERVAL)


if __name__ == "__main__":
    p = mp.Process(target=run_speedtest)
    p.start()

    serve()

#!/usr/bin/env python3
"""PokeMulti relay: copies the link files between two PCs over TCP.

Each PC runs DeSmuME with one player script and one relay.
  PC of player 1:  python relay.py host --me 1
  PC of player 2:  python relay.py join --me 2 --address <IP of PC 1>

The relay sends the local file (pN.txt) when it changes, and writes what it
receives into the partner's file. It uses only the Python standard library.
"""
import argparse
import os
import socket
import sys
import threading
import time

VERSION = "PM1"
DEFAULT_PORT = 47811
DEFAULT_LINK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "link")


def valid_line(line):
    """True for one complete protocol line (see lua/coop/protocol.lua)."""
    parts = line.split("|")
    return len(parts) == 9 and parts[0] == VERSION and parts[-1] == "END"


def read_local(path):
    try:
        with open(path, "r", encoding="ascii", errors="replace") as f:
            line = f.readline().strip()
    except OSError:
        return None
    return line if valid_line(line) else None


def write_atomic(path, line):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="ascii", errors="replace", newline="\n") as f:
        f.write(line + "\n")
    for _ in range(5):
        try:
            os.replace(tmp, path)
            return True
        except PermissionError:
            time.sleep(0.01)  # Windows: the emulator is reading the file
    return False


class Pump:
    """Moves lines between one socket and the two link files."""

    def __init__(self, sock, out_path, in_path, interval=0.03, log=print):
        self.sock = sock
        self.out_path = out_path
        self.in_path = in_path
        self.interval = interval
        self.log = log
        self.stop = threading.Event()
        self.sent = 0
        self.received = 0

    def send_loop(self):
        last = None
        try:
            while not self.stop.is_set():
                line = read_local(self.out_path)
                if line and line != last:
                    self.sock.sendall((line + "\n").encode("ascii", "replace"))
                    last = line
                    self.sent += 1
                time.sleep(self.interval)
        except OSError as e:
            self.log(f"envio parou: {e}")
        finally:
            self.stop.set()

    def recv_loop(self):
        buf = b""
        try:
            while not self.stop.is_set():
                data = self.sock.recv(4096)
                if not data:
                    break
                buf += data
                while b"\n" in buf:
                    raw, buf = buf.split(b"\n", 1)
                    line = raw.decode("ascii", "replace").strip()
                    if valid_line(line):
                        write_atomic(self.in_path, line)
                        self.received += 1
                if len(buf) > 65536:
                    buf = b""  # garbage, drop it
        except OSError as e:
            self.log(f"recepcao parou: {e}")
        finally:
            self.stop.set()

    def run(self):
        threads = [threading.Thread(target=self.send_loop, daemon=True),
                   threading.Thread(target=self.recv_loop, daemon=True)]
        for t in threads:
            t.start()
        while not self.stop.is_set():
            self.stop.wait(0.2)
        try:
            self.sock.close()
        except OSError:
            pass


def connect(args):
    if args.mode == "host":
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((args.bind, args.port))
        srv.listen(1)
        print(f"Aguardando o parceiro na porta {args.port}...")
        sock, addr = srv.accept()
        srv.close()
        print(f"Parceiro conectado: {addr[0]}")
    else:
        while True:
            try:
                sock = socket.create_connection((args.address, args.port), timeout=5)
                break
            except OSError as e:
                print(f"Sem conexao ({e}). Nova tentativa em 2 s...")
                time.sleep(2)
        sock.settimeout(None)
        print(f"Conectado a {args.address}:{args.port}")
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    return sock


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("mode", choices=["host", "join"])
    p.add_argument("--me", type=int, choices=[1, 2], required=True, help="your player number")
    p.add_argument("--address", help="IP of the host (join only)")
    p.add_argument("--port", type=int, default=DEFAULT_PORT)
    p.add_argument("--bind", default="0.0.0.0")
    p.add_argument("--link", default=DEFAULT_LINK, help="folder with the link files")
    args = p.parse_args(argv)
    if args.mode == "join" and not args.address:
        p.error("join needs --address")

    partner = 2 if args.me == 1 else 1
    out_path = os.path.join(args.link, f"p{args.me}.txt")
    in_path = os.path.join(args.link, f"p{partner}.txt")
    os.makedirs(args.link, exist_ok=True)

    while True:
        sock = connect(args)
        Pump(sock, out_path, in_path).run()
        print("Conexao perdida.")
        if args.mode == "join":
            time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)

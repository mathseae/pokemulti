"""Tests for relay/relay.py. Run: python -I tests/run_tests.py"""
import os
import socket
import sys
import tempfile
import threading
import time
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "relay"))
import relay  # noqa: E402

LINE1 = "PM1|1|IRBO|389|12|30|2|Ana|END"
LINE2 = "PM1|7|IRBO|389|14|31|0|Bia|END"


def wait_for(cond, timeout=3.0):
    end = time.time() + timeout
    while time.time() < end:
        if cond():
            return True
        time.sleep(0.01)
    return False


class ValidLine(unittest.TestCase):
    def test_valid(self):
        self.assertTrue(relay.valid_line(LINE1))

    def test_invalid(self):
        for bad in ["", "PM1|1|IRBO", "PM2|1|IRBO|1|2|3|4|A|END", "PM1|1|IRBO|1|2|3|4|A|EN"]:
            self.assertFalse(relay.valid_line(bad), bad)


class PumpEndToEnd(unittest.TestCase):
    def test_two_sides_exchange_lines(self):
        with tempfile.TemporaryDirectory() as d1, tempfile.TemporaryDirectory() as d2:
            sa, sb = socket.socketpair()
            pa = relay.Pump(sa, os.path.join(d1, "p1.txt"), os.path.join(d1, "p2.txt"), 0.01, lambda m: None)
            pb = relay.Pump(sb, os.path.join(d2, "p2.txt"), os.path.join(d2, "p1.txt"), 0.01, lambda m: None)
            for p in (pa, pb):
                threading.Thread(target=p.run, daemon=True).start()

            relay.write_atomic(os.path.join(d1, "p1.txt"), LINE1)
            relay.write_atomic(os.path.join(d2, "p2.txt"), LINE2)
            self.assertTrue(wait_for(lambda: relay.read_local(os.path.join(d2, "p1.txt")) == LINE1))
            self.assertTrue(wait_for(lambda: relay.read_local(os.path.join(d1, "p2.txt")) == LINE2))

            # A half-written local file is not sent.
            with open(os.path.join(d1, "p1.txt"), "w") as f:
                f.write("PM1|2|IRBO|389")
            time.sleep(0.1)
            self.assertEqual(relay.read_local(os.path.join(d2, "p1.txt")), LINE1)
            self.assertEqual(pa.sent, 1)

            pa.stop.set(); pb.stop.set()
            sa.close(); sb.close()


if __name__ == "__main__":
    unittest.main()

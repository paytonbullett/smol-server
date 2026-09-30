import sys
import os
import traceback
import linecache

# Force Python to flush stdout/stderr immediately so CloudWatch doesn't drop logs
sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

def print_diagnostic_code(exc_type, exc_value, exc_tb):
    """Formats and prints the exact file, line, and surrounding code on crash."""
    tb = traceback.extract_tb(exc_tb)
    if not tb:
        print(f"CRITICAL ERROR: {exc_type.__name__}: {exc_value}", file=sys.stderr)
        return

    last_frame = tb[-1]
    filename = last_frame.filename
    lineno = last_frame.lineno
    func_name = last_frame.name

    print("\n" + "=" * 80, file=sys.stderr)
    print("🔥 CRITICAL PYTHON STARTUP ERROR DETECTED 🔥", file=sys.stderr)
    print("=" * 80, file=sys.stderr)
    print(f"ERROR TYPE: {exc_type.__name__}", file=sys.stderr)
    print(f"MESSAGE:    {exc_value}", file=sys.stderr)
    print(f"LOCATION:   File '{filename}', line {lineno}, in {func_name}", file=sys.stderr)
    print("-" * 80, file=sys.stderr)
    print("SURROUNDING CODE:", file=sys.stderr)

    if os.path.exists(filename):
        start = max(1, lineno - 5)
        end = lineno + 5
        for i in range(start, end + 1):
            line = linecache.getline(filename, i).rstrip()
            prefix = "==> " if i == lineno else "    "
            print(f"{prefix}{i:4d} | {line}", file=sys.stderr)
    else:
        print(f"  [Source file {filename} not accessible]", file=sys.stderr)

    print("=" * 80 + "\n", file=sys.stderr)
    sys.stderr.flush()
    sys.stdout.flush()

# Set global exception hook to catch any unhandled crash
sys.excepthook = print_diagnostic_code

if __name__ == "__main__":
    print("[DEBUG LAUNCHER] Testing server.py imports...", file=sys.stderr)
    sys.stderr.flush()

    try:
        # Step 1: Force import of server.py to catch top-level syntax/import errors
        import server
        print("[DEBUG LAUNCHER] server.py imported successfully.", file=sys.stderr)

        # Step 2: Import uvicorn
        import uvicorn
        print("[DEBUG LAUNCHER] Starting Uvicorn on port 8080...", file=sys.stderr)
        sys.stderr.flush()

        # Step 3: Run Uvicorn directly
        uvicorn.run(server.app, host="0.0.0.0", port=8080, log_level="debug")

    except Exception as e:
        print_diagnostic_code(type(e), e, sys.exc_info()[2])
        # Force immediate exit with error code so Lambda stops instantly
        os._exit(1)

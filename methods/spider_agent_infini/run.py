import argparse
import datetime
import logging
import os
import sys


#  Logger Configs {{{ #
logger = logging.getLogger("spider_agent_infini")
logger.setLevel(logging.DEBUG)

datetime_str: str = datetime.datetime.now().strftime("%Y%m%d@%H%M%S")

os.makedirs("logs", exist_ok=True)

file_handler = logging.FileHandler(os.path.join("logs", "normal-{:}.log".format(datetime_str)), encoding="utf-8")
debug_handler = logging.FileHandler(os.path.join("logs", "debug-{:}.log".format(datetime_str)), encoding="utf-8")
stdout_handler = logging.StreamHandler(sys.stdout)
sdebug_handler = logging.FileHandler(os.path.join("logs", "sdebug-{:}.log".format(datetime_str)), encoding="utf-8")

file_handler.setLevel(logging.INFO)
debug_handler.setLevel(logging.DEBUG)
stdout_handler.setLevel(logging.INFO)
sdebug_handler.setLevel(logging.DEBUG)

formatter = logging.Formatter(
    fmt="\x1b[1;33m[%(asctime)s \x1b[31m%(levelname)s \x1b[32m%(module)s/%(lineno)d-%(processName)s\x1b[1;33m] \x1b[0m%(message)s")
file_handler.setFormatter(formatter)
debug_handler.setFormatter(formatter)
stdout_handler.setFormatter(formatter)
sdebug_handler.setFormatter(formatter)

stdout_handler.addFilter(logging.Filter("spider_agent_infini"))
sdebug_handler.addFilter(logging.Filter("spider_agent_infini"))

logger.addHandler(file_handler)
logger.addHandler(debug_handler)
logger.addHandler(stdout_handler)
logger.addHandler(sdebug_handler)
#  }}} Logger Configs #

def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run end-to-end evaluation on the benchmark"
    )

    parser.add_argument("--max_steps", type=int, default=20)
    parser.add_argument("--max_memory_length", type=int, default=30)
    parser.add_argument("--suffix", "-s", type=str, default="gpt-4-try1")

    parser.add_argument("--model", type=str, default="gpt-4o")
    parser.add_argument("--temperature", type=float, default=0.5)
    parser.add_argument("--top_p", type=float, default=0.9)
    parser.add_argument("--max_tokens", type=int, default=2500)
    parser.add_argument("--stop_token", type=str, default=None)

    # example config
    parser.add_argument("--test_path", "-t", type=str, default="./examples/spider2-infini.jsonl")
    parser.add_argument("--example_index", "-i", type=str, default="all",
                        help="index range of the examples to run, e.g., '0-10', '2,3', 'all'")
    parser.add_argument("--example_name", "-n", type=str, default="", help="name of the example to run")
    parser.add_argument("--overwriting", action="store_true", default=False)
    parser.add_argument("--retry_failed", action="store_true", default=False)

    # output related
    parser.add_argument("--output_dir", type=str, default="output")
    parser.add_argument("--plan", action="store_true")

    # submission format: SQL file or CSV result
    parser.add_argument("--mode", type=str, choices=["sql", "csv"], default="csv",
                        help="submission mode: 'sql' to submit a .sql file, 'csv' to submit a .csv result file")

    args = parser.parse_args()
    return args


def run():
    args = config()
    logger.info("Args: %s", args)

    # 接下来我们先读取jsonl文件, 



if __name__ == "__main__":
    run()

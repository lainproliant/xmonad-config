#!/usr/bin/env python3

import subprocess
from jinja2 import Template


# -------------------------------------------------------------------
def xrdb_query():
    resources = {}
    output = subprocess.check_output(["xrdb", "-query"]).decode("utf-8")
    lines = [x for x in output.split("\n") if x]

    for line in lines:
        key, value, *_ = (s.strip() for s in line.split(":"))
        resources[key] = value

    return resources


# -------------------------------------------------------------------
X11R = xrdb_query()


# -------------------------------------------------------------------
def load_template():
    with open("xmonad.hs.jinja", "r") as infile:
        return Template(infile.read())


# -------------------------------------------------------------------
def main():
    template = load_template()
    print(template.render(normal_border_color=X11R["*_base01"],
                          focused_border_color=X11R["*_base05"]))


# -------------------------------------------------------------------
if __name__ == "__main__":
    main()

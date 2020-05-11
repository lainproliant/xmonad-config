#!/usr/bin/env python3

from jinja2 import Template

from base16 import Base16


# -------------------------------------------------------------------
def load_template():
    with open("xmonad.hs.jinja", "r") as infile:
        return Template(infile.read())


# -------------------------------------------------------------------
def main():
    template = load_template()
    print(template.render(base16=Base16.load_from_xdefaults()))


# -------------------------------------------------------------------
if __name__ == "__main__":
    main()

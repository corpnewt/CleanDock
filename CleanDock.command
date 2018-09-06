#!/usr/bin/python
# 0.0.0
from Scripts import *
import os, tempfile, datetime, shutil, time, plistlib, json, sys, subprocess

class CleanDock:
    def __init__(self, **kwargs):
        # Get the tools we need
        self.script_folder = "Scripts"
        self.settings_file = os.path.join("Scripts", "settings.json")
        self.dock_prefs = os.path.abspath(os.path.expanduser("~/Library/Preferences/com.apple.dock.plist"))
        cwd = os.getcwd()
        os.chdir(os.path.dirname(os.path.realpath(__file__)))
        if self.settings_file and os.path.exists(self.settings_file):
            self.settings = json.load(open(self.settings_file))
        else:
            self.settings = None
        os.chdir(cwd)
    
    def convert_to_xml(self, path):
        if not os.path.exists(path):
            return 1
        try:
            p = subprocess.Popen(["plutil", "-convert", "xml1", path], stdout=subprocess.PIPE)
            p_string, e = p.communicate()
            return p.returncode
        except:
            return 1

    def convert_to_binary(self, path):
        if not os.path.exists(path):
            return 1
        try:
            p = subprocess.Popen(["plutil", "-convert", "binary1", path], stdout=subprocess.PIPE)
            p_string, e = p.communicate()
            return p.returncode
        except:
            return 1
    
    def main(self):
        # Let's load the plist (if it exists), and run through the
        # list of exclusions and ditch any that don't exist on there
        if not self.settings:
            print("Looks like the settings file doesn't exist.  Abort!")
            exit(1)
        if not os.path.exists(self.dock_prefs):
            print("Looks like the dock preferences don't exist.  Abort!")
            exit(1)
        # Load the plist
        if self.convert_to_xml(self.dock_prefs):
            print("Error converting plist to xml.  Abort!")
            exit(1)
        with open(self.dock_prefs, "rb") as f:
            dock = plist.load(f)
        apps = dock["persistent-apps"]
        print("Found {} dock entr{}.\nIterating...".format(len(apps), "y" if len(apps) == 1 else "ies"))
        remove = []
        for x in apps:
            if not x["tile-data"]["file-label"].lower() in self.settings["allow"]:
                print("{} not in allowed - removing...".format(x["tile-data"]["file-label"]))
                remove.append(x)
        if not len(remove):
            print("No apps to remove!")
            exit()
        for app in remove:
            apps.remove(app)
        # At this point - we've removed something - let's flush changes
        print("Saving...")
        with open(self.dock_prefs, "wb") as f:
            plist.dump(dock, f)
        print("Converting to binary...")
        if self.convert_to_binary(self.dock_prefs):
            print("Error converting plist to binary - still xml though... allowing.")
        print("Restarting dock...")
        p = subprocess.Popen(["killall", "Dock"])


if __name__ == '__main__':
    c = CleanDock()
    c.main()

#
# Define hard-coded paths used by all programs
# Read project.cfg
#

BEGIN {

  # Directories should have a trailing slash
  Home = "/home/adminuser/wam/"

  # Shared directory between Windows and VirtualBox Linux guest
  Ramdisk = "/mnt/ramdisk/"

  # String included with http requests shows in remote logs. Include name of program and your contact info.
  Agent = "http://en.wikipedia.org/wiki/User:Green_Cardamom (ask me about WAM)"

  # Default wget options (include lead/trail spaces)
  Wget_opts = " --no-cookies --ignore-length --user-agent=\"" Agent "\" --no-check-certificate --tries=5 --timeout=120 --waitretry=60 --retry-connrefused "

  Exe["rm"] = "/bin/rm"
  Exe["mv"] = "/bin/mv"
  Exe["cp"] = "/bin/cp"
  Exe["ls"] = "/bin/ls"
  Exe["cat"] = "/bin/cat"
  Exe["grep"] = "/bin/grep"
  Exe["wc"] = "/usr/bin/wc"
  Exe["touch"] = "/usr/bin/touch"
  Exe["diff"] = "/usr/bin/diff"
  Exe["head"] = "/usr/bin/head"
  Exe["tail"] = "/usr/bin/tail"
  Exe["date"] = "/bin/date"
  Exe["sleep"] = "/bin/sleep"
  Exe["wget"] = "/usr/bin/wget"
  Exe["mkdir"] = "/bin/mkdir"
  Exe["python"] = "/usr/bin/python"       # needed for url en/de-coding
  Exe["python3"] = "/usr/bin/python3"     # needed for url en/de-coding

  Exe["wam"] = Home "wam"

  Exe["pywikibotsavepage"] = "/home/adminuser/pywikibot/core_stable/savepage.py"
  # Add this to your .login or .bashrc script
  #  setenv PYWIKIBOT2_DIR /home/adminuser/pywikibot/core_stable/
 
  delete Config
  readprojectcfg()
 
}

#
# Read project.cfg into Config[]
#
function readprojectcfg(  a,b,c,i,p) {

  checkexists(Home "project.cfg", "init.awk", "exit")

  c = split(readfile(Home "project.cfg"), a, "\n")
  while(i++ < c){
    if(a[i] == "" || substr(a[i],1,1) ~ /#/) # Ignore comment lines starting with #
      continue
    if(a[i] ~ /^default.id/) {
      split(a[i],b,"=")
      Config["default"]["id"] = strip(b[2])
    }
    if(a[i] ~ /[.]data/) {
      split(a[i], b, "=")
      p = gensub(/[.]data$/,"","g",strip(b[1]))
      Config[p]["data"] = strip(b[2])
    }
    if(a[i] ~ /[.]meta/) {
      split(a[i], b, "=")
      p = gensub(/[.]meta$/,"","g",strip(b[1]))
      Config[p]["meta"] = strip(b[2])
    }
  }

}

#!/usr/local/bin/gawk -E

# Create data files/directories and launch wam.awk

# The MIT License (MIT)
#
# Copyright (c) 2016 by User:Green Cardamom (at en.wikipedia.org)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,         
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

@include "init.awk"
@include "library.awk"
@include "getopt.awk"

BEGIN {

  while ((C = getopt(ARGC, ARGV, "hd:p:n:")) != -1) {
      opts++
      if(C == "p")                 #  -p <project>   Use project name. Default in project.cfg
        pid = verifypid(Optarg)
      if(C == "n")                 #  -n <name>      Name to process.
        namewiki = verifyval(Optarg)
      if(C == "d")                 #  -d <y|n>       Dry run. "y" = push changes to Wikipedia.
        dryrun = verifyval(Optarg)

      if(C == "h") {
        usage()
        exit
      }
  }

  if( pid ~ /error/ || ! opts || namewiki == "" ){
    usage()
    exit
  }

# library.awk .. load Project[] paths via project.cfg
  setProject(pid)    

# Create temp directory
  nano = substr(sys2var( Exe["date"] " +\"%N\""), 1, 6)
  wm_temp = Project["data"] "wm-" sys2var( Exe["date"] " +\"%m%d%H%M%S\"") nano "/" 
  if(!mkdir(wm_temp)) {
    print "driver.awk: unable to create temp file" > "/dev/stderr"
    exit
  }

# Save wikisource
  print getwikisource(namewiki, "dontfollow") > wm_temp "article.txt"
  close(wm_temp "article.txt")
  stripfile(wm_temp "article.txt", "inplace")

  command = "cp " wm_temp "article.txt " wm_temp "article.txt.2"
  sys2var(command)

# Save namewiki
  print namewiki > wm_temp "namewiki.txt"
  close(wm_temp "namewiki.txt")

# Create index.temp entry (re-assemble when done with "project -j") 

  print namewiki "|" wm_temp >> Project["indextemp"]
  close(Project["indextemp"])

# Run wam and save result to /wm_temp/article.new.txt

  print "\n"namewiki"\n" > "/dev/stderr"

  command = Exe["wam"] " -p \"" Project["id"] "\" -n " shquote(namewiki) " -s \"" wm_temp "\"article.txt"  
  changes = sys2var(command)
  if(changes) {
    print "    Found " changes " change(s) for " namewiki > "/dev/stderr"
    sendlog(Project["discovered"], namewiki, "")
  }
  else {
    if(checkexists(wm_temp "article.new.txt")) {
      sys2var( Exe["rm"] " -- " wm_temp "article.new.txt")
    }
  }

# Push changes to Wikipedia with Pywikibot 

  if(checkexists(wm_temp "article.new.txt") && dryrun == "y" && stopbutton() == "RUN" ) {
    article = wm_temp "article.new.txt"
    summary = readfile(wm_temp "editsummary")
    if(length(summary) < 5)
      summary = "Archive template(s) merged to [[template:webarchive]] ([[User:Green_Cardamom/Webarchive_template_merge|WAM]])"

    command = Exe["pywikibotsavepage"] " " shquote(namewiki) " \"" summary "\" \"" article "\""

    result = sys2var(command)

    if(result ~ /OKMEDIC/) { # Success
      prnt("driver.awk: Status successful (savepage.py). Page uploaded to Wikipedia. " name)
      print namewiki >> Project["discovereddone"]
      close(Project["discovereddone"])
    }
    else {
      prnt("driver.awk: Error uploading to Wikipedia (savepag.py). " name)
      print namewiki >> Project["discoverederror"]
      close(Project["discoverederror"])
    }
  }

}


#
# Check status of stop button page
#
#  return RUN or STOP
#
function stopbutton(button,bb) {

  button = http2var("https://en.wikipedia.org/wiki/User:GreenC_bot/button?action=raw")
  if(button ~ /[Aa]ction[ ]{0,}[=][ ]{0,}[Rr][Uu][Nn]/) 
    return "RUN"

  prnt("driver.awk: ABORTED by stop button page. " name)
  while(bb++ < 5)  {                                            # Ring my bell...
    system("/home/adminuser/scripts/bell")
    sleep(2)
    system("/home/adminuser/scripts/bell")
    sleep(4)
  }
  sleep(864000)      # sleep up to 24 days .. no other way to stop GNU parallel from running
  return "STOP"

}

# 
# Print and log messages
# 
function prnt(msg) {
  if( length(msg) > 0 ) {
    print msg >> "/dev/stderr"
    print(strftime("%Y%m%d %H:%M:%S") " " msg) >> Home "driver.log"
    close(Home "driver.log")
  }
}

function usage() {

  print ""
  print "Driver - create data files and launch wam.awk"
  print ""
  print "Usage:"        
  print "       -p <project>   Project name. Optional, defaults to project.cfg"
  print "       -n <name>      Name to process. Required"
  print "       -d <y|n>       Dry run. -d y means push changes to Wikipedia."
  print "       -h             Help"
  print ""
  print "Example: "
  print "          driver -n \"Charles Dickens\" -p cb14feb16"
  print ""
}

#!/usr/bin/awk -bE

#
# Wikiget - command-line access to some Wikimedia API functions
#

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


BEGIN {

  Contact = "User:<username> (en.wikipedia.org)"              # Your contact info - informational only for API Agent string
  G["program"] = "Wikiget"
  G["version"] = "0.1"
  G["agent"] = Program " " G["version"] " " Contact
  G["maxlag"] = "5"                                           # Wikimedia API max lag default
  G["lang"] = "en"                                            # Wikipedia language default
                                 
  setup("wget curl lynx")                                     # Use wget, curl or lynx - searching PATH in this order
  Optind = Opterr = 1 
  parsecommandline()
  processarguments()

}

# _____________________________ Command line parsing and argument processing ______________________________________________

#
# Parse command-line
#
function parsecommandline(c, opts) {

  while ((c = getopt(ARGC, ARGV, "hVfps:e:u:m:b:l:n:w:c:")) != -1) {
      opts++
      if(c == "h") {
        usage()
        usage_extended()
        exit
      }

      if(c == "b") {               #  -b <entity>     Backlinks for entity ( -b "Template:Project Gutenberg" )
        Arguments["main"] = verifyval(Optarg)
        Arguments["main_c"] = "b"
      }

      if(c == "c") {               #  -b <entity>     List articles in a category ( -c "Category:1900 births" )
        Arguments["main"] = verifyval(Optarg)
        Arguments["main_c"] = "c"
      }

      if(c == "u") {               #  -u <username>   User contributions ( -u "User:Green Cardamom")
        Arguments["main"] = verifyval(Optarg)
        Arguments["main_c"] = "u"
      }
      if(c == "s")                 #  -s <time>       Start time for -u (required w/ -u)
        Arguments["starttime"] = verifyval(Optarg)
      if(c == "e")                 #  -e <time>       End time for -u (required w/ -u)
        Arguments["endtime"] = verifyval(Optarg)
      if(c == "n")                 #  -n <namespace>  Namespace for -u (optional w/ -u)
        Arguments["namespace"] = verifyval(Optarg)
      
      if(c == "w") {               #  -w <article>    Print wiki text 
        Arguments["main"] = verifyval(Optarg)
        Arguments["main_c"] = "w"
      }
      if(c == "f")                 #  -f              Don't follow redirect (return source of redirect page)
        Arguments["followredirect"] = "false"
      if(c == "p")                 #  -p              Plain text (strip wiki markup)
        Arguments["plaintext"] = "true"

      if(c == "m")                 #  -m <maxlag>     Maxlag setting when using API, default set in BEGIN{} section
        Arguments["maxlag"] = verifyval(Optarg)
      if(c == "l")                 #  -l <lang>       Language code, default set in BEGIN{} section
        Arguments["lang"] = verifyval(Optarg)
      if(c == "V") {               #  -V              Version and copyright info.
        version()
        exit
      }  
  }
  if(opts < 1) {
    usage()
    exit
  }
  return 
}

#
# Process arguments
#
function processarguments() {

  if(Arguments["lang"])                                     # options
    G["lang"] = Arguments["lang"]
  if(isanumber(Arguments["maxlag"])) 
    G["maxlag"] = Arguments["maxlag"]
  if(isanumber(Arguments["namespace"])) 
    G["namespace"] = Arguments["namespace"]
  if(Arguments["followredirect"] == "false")
    G["followredirect"] = "false"
  else
    G["followredirect"] = "true"
  if(Arguments["plaintext"] == "true")
    G["plaintext"] = "true"
  else
    G["plaintext"] = "false"
  if(Arguments["plaintext"] == "true")
    G["plaintext"] = "true"

  if(Arguments["main_c"] == "b") {                          # backlinks
    if ( entity_exists(Arguments["main"]) ) {
      if ( ! backlinks(Arguments["main"]) )
        print "No backlinks for " Arguments["main"] 
    }
  }
  else if(Arguments["main_c"] == "c") {                     # categories
    category(Arguments["main"])
  }
  else if(Arguments["main_c"] == "u") {                     # user contributions
    if(! isanumber(Arguments["starttime"]) || ! isanumber(Arguments["endtime"])) {
      print "Invalid start time (-s) or end time (-e)\n"
      usage()
      exit
    }
    Arguments["starttime"] = Arguments["starttime"] "000000"
    Arguments["endtime"] = Arguments["endtime"] "235959"
    if ( ! ucontribs(Arguments["main"],Arguments["starttime"],Arguments["endtime"]) )
      print "No user and/or edits found."
  }
  else if(Arguments["main_c"] == "w") {                     # wiki text
    if ( entity_exists(Arguments["main"]) ) {
      if(G["plaintext"] == "true")
        print wikitextplain(Arguments["main"])
      else
        print wikitext(Arguments["main"])
    }
    else {
      print "Unable to find " Arguments["main"]
      exit
    }
  }
  else {
    usage()
    exit
  }
}

#
# usage()
#
function usage() {
  print ""              
  print "Wikiget - command-line access to some Wikimedia API functions"
  print ""
  print "Usage:"         
  print ""
  print " Backlinks:"
  print "       -b <name>        Backlinks for article, template, userpage, etc.."
  print ""
  print " User contributions:"
  print "       -u <username>    User contributions"
  print "         -s <starttime> Start time in YMD format (-s 20150101). Required with -u"
  print "         -e <endtime>   End time in YMD format (-e 20151231). If same as -s does 24hr range. Required with -u"
  print "         -n <namespace> (option) Pipe-separated numeric value(s) of namespace. See -h for codes and examples."
  print ""
  print " Category list:"
  print "       -c <category>    List articles in a category"
  print ""
  print " Print wiki text:"
  print "       -w <article>     Print wiki text of article"
  print "         -p             (option) Plain-text version (strip wiki markup)"
  print "         -f             (option) Don't follow redirects (print redirect page source)"
  print ""
  print " Global options:"
  print "       -l <language>    Wikipedia language code (default: " G["lang"] "). See https://en.wikipedia.org/wiki/List_of_Wikipedias"
  print "       -m <#>           API maxlag value (default: " G["maxlag"] "). See https://www.mediawiki.org/wiki/API:Etiquette#Use_maxlag_parameter"
  print "       -V               Version and copyright"
  print "       -h               Help with examples"
  print ""
}
function usage_extended() {
  print "Examples:"
  print ""
  print " Backlinks:"
  print "   wikiget -b \"Template:Project Gutenberg\""
  print "   wikiget -b \"User:Jimbo Wales\""
  print "   wikiget -b \"Paris (Idaho)\" -l fr  (show backlinks for article \"Paris (Idaho)\" on the French Wiki)"
  print ""
  print " User contributions:"
  print "   wikiget -u \"User:Jimbo Wales\" -s 20010910 -e 20010912          (show all edits from 9/10-9/12 on 2001)"  
  print "   wikiget -u \"User:Jimbo Wales\" -s 20010911 -e 20010911          (show all edits during the 24hrs of 9/11)"  
  print "   wikiget -u \"User:Jimbo Wales\" -s 20010911 -e 20010930 -n 0     (articles only)"
  print "   wikiget -u \"User:Jimbo Wales\" -s 20010911 -e 20010930 -n 1     (talk pages only)"
  print "   wikiget -u \"User:Jimbo Wales\" -s 20010911 -e 20010930 -n \"0|1\" (talk and articles only)"
  print "   -n codes: https://www.mediawiki.org/wiki/Extension_default_namespaces"
  print ""
  print " Category list:"
  print "   wikiget -c \"Category:1900 births\"        (list articles in category)"
  print ""
  print " Print wiki text:"
  print "   wikiget -w \"Paris\" -p                    (print wiki text of article \"Paris\" on the English Wiki)"
  print "   wikiget -w \"China\" -p -l fr              (print plain-text of article \"China\" on the French Wiki)"
  print ""  
}
function version() {
  print "Wikiget " G["version"]
  print "Copyright (C) 2016 User:Green Cardamom (en.wikipedia.org)"
  print
  print "The MIT License (MIT)"
  print
  print "Permission is hereby granted, free of charge, to any person obtaining a copy"      
  print "of this software and associated documentation files (the "Software"), to deal"   
  print "in the Software without restriction, including without limitation the rights"                
  print "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell"    
  print "copies of the Software, and to permit persons to whom the Software is"              
  print "furnished to do so, subject to the following conditions:"
  print
  print "The above copyright notice and this permission notice shall be included in"
  print "all copies or substantial portions of the Software."
  print
  print "THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"
  print "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
  print "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
  print "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
  print "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
  print "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN"
  print "THE SOFTWARE."
  print 
}

# 
# Verify an argument has a valid value                
#
function verifyval(val) {

  if(val == "" || substr(val,1,1) ~ /^[-]/) {
    print "\nCommand line argument has an empty value when it should have something.\n" > "/dev/stderr"
    usage()
    exit
  }
  return val
}              

#
# getopt()
#   Credit: GNU awk (/usr/local/share/awk/getopt.awk)
#   Pre-define these globaly: Optind = Opterr = 1 
#
function getopt(argc, argv, options,    thisopt, i) {

    if (length(options) == 0)    # no options given
        return -1

    if (argv[Optind] == "--") {  # all done
        Optind++
        _opti = 0
        return -1
    } else if (argv[Optind] !~ /^-[^:[:space:]]/) {
        _opti = 0
        return -1
    }
    if (_opti == 0)
        _opti = 2
    thisopt = substr(argv[Optind], _opti, 1)
    Optopt = thisopt
    i = index(options, thisopt)
    if (i == 0) {
        if (Opterr)
            printf("%c -- invalid option\n", thisopt) > "/dev/stderr"
        if (_opti >= length(argv[Optind])) {
            Optind++
            _opti = 0
        } else
            _opti++
        return "?"
    }
    if (substr(options, i + 1, 1) == ":") {
        # get option argument
        if (length(substr(argv[Optind], _opti + 1)) > 0)
            Optarg = substr(argv[Optind], _opti + 1)
        else
            Optarg = argv[++Optind]
        _opti = 0
    } else
        Optarg = ""
    if (_opti == 0 || _opti >= length(argv[Optind])) {
        Optind++
        _opti = 0
    } else
        _opti++
    return thisopt
}

# _____________________________ Setup __________________________________________________

#
# Check for existence of needed programs and files.
#
function setup(files_system) {

        if ( ! files_verify("ls") ) {
            printf("Unable to find ls. Please ensure your crontab has paths set eg.:PATH=/sbin:/bin:/usr/sbin:/usr/local/bin:/usr/bin\n")
            exit
        }
        if ( ! files_verify(files_system) ) {
            exit
        }
}

#
# Verify existence of programs in path
# Return 0 if fail.
#
function files_verify(files_system,
        a, i, missing) {

        missing = 0
        split(files_system, a, " ")
        for ( i in a ) {
            if ( ! sys2var(sprintf("command -v %s",a[i])) ) {
                if(a[i] == "wget") G["wget"] = "false"
                if(a[i] == "curl") G["curl"] = "false"
                if(a[i] == "lynx") G["lynx"] = "false"
#                missing++
#                print "Abort: command not found in PATH: " a[i]
            }
            else if(a[i] == "wget") G["wget"] = "true"
            else if(a[i] == "curl") G["curl"] = "true"
            else if(a[i] == "lynx") G["lynx"] = "true"
        }

        if(G["wget"] == "false" && G["curl"] == "false" && G["lynx"] == "false") {
          print "Abort: unable to find wget, curl or lynx in PATH. Manually set a location for one of these in function http2var()."
          return 0
        }
        else if(G["wget"] == "true")
          G["wta"] = "wget"
        else if(G["curl"] == "true")
          G["wta"] = "curl"
        else if(G["lynx"] == "true")
          G["wta"] = "lynx"

        return 1
}

# _____________________________ Category list (-c) ______________________________________________

#
# User Category list main
#
function category(entity) {

        # MediaWiki API:Categorymembers
        #  https://www.mediawiki.org/wiki/API:Categorymembers

        if(entity !~ /^[Cc]ategory[:]/)
          entity = "Category:" entity

        url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=categorymembers&cmtitle=" urlencodeawk(entity) "&cmtype=page&cmprop=title&cmlimit=500&format=xml&maxlag=" G["maxlag"]

        results = getcategory(url, entity)

        results = uniq(results)
        if ( length(results) > 0)
          print results
        return length(results)
}
function getcategory(url, entity,   xmlin, xmlout, continuecode) {

        xmlin = http2var(url)
        xmlout = parsexmlcat(xmlin)
        continuecode = getcontinuecat(xmlin)
        while ( continuecode ) {
            url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=categorymembers&cmtitle=" urlencodeawk(entity) "&cmtype=page&cmprop=title&cmlimit=500&format=xml&maxlag=" G["maxlag"] "&continue=-||&cmcontinue=" continuecode 
            xmlin = http2var(url)
            xmlout = xmlout "\n" parsexmlcat(xmlin)
            continuecode = getcontinuecat(xmlin)
        }
        return xmlout
}
function getcontinuecat(xmlin,      re,a,b,c) {

        # eg. <continue cmcontinue="20160214061737|704890823" continue="-||"/>
        match(xmlin, /cmcontinue="[^\"]*"/, a)
        split(a[0], b, "\"")
        if ( length(b[2]) > 0)
            return b[2]
        return 0
}
function parsexmlcat(xmlin,   f,g,e,c,a,i,b,d,out,comment,title,dest1,dest2){

  if(xmlin ~ /error code="maxlag"/) {
    print "Max lag (" G["maxlag"] ") exceeded - aborting. Try again when API servers are less busy, or increase Maxlag (-m)" > "/dev/stderr"
    exit
  }

  f = split(xmlin,e,/<categorymembers>|<\/categorymembers>/)
  c = split(e[2],a,"/>")

  while(++i < c) {
    if(a[i] ~ /title[=]/) {
      match(a[i], /title="[^\"]*"/,k) 
      split(gensub("title=","","g",k[0]), g, "\"")
      title = convertxml(g[2])
      match(a[i], /parsedcomment="[^\"]*"/,k)
      comment = gensub("parsedcomment=","","g",k[0])
      out = out title "\n"
    }
  }
  return strip(out)
}

# _____________________________ User Contributions (-u) ______________________________________________

#
# User Contribs main 
#
function ucontribs(entity,sdate,edate,      url, results) {

        # MediaWiki namespace codes
        #  https://www.mediawiki.org/wiki/Extension_default_namespaces

        if(entity !~ /^[Uu]ser[:]/)
          entity = "User:" entity

        url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=usercontribs&ucuser=" urlencodeawk(entity) "&uclimit=500&ucstart=" sdate "&ucend=" edate "&ucdir=newer&ucnamespace=" G["namespace"] "&ucprop=title|parsedcomment&format=xml&maxlag=" G["maxlag"]

        results = getucontribs(url, entity, sdate, edate) 

        results = uniq(results)
        if ( length(results) > 0) 
          print results
        return length(results)
}
function getucontribs(url, entity, sdate, edate,         xmlin, xmlout, continuecode) {

        xmlin = http2var(url)
        xmlout = parsexmlucon(xmlin)
        continuecode = getcontinueuc(xmlin)

        while ( continuecode ) {
            url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=usercontribs&ucuser=" urlencodeawk(entity) "&uclimit=500&continue=-||&uccontinue=" continuecode "&ucstart=" sdate "&ucend=" edate "&ucdir=newer&ucnamespace=" G["namespace"] "&ucprop=title|parsedcomment&format=xml&maxlag=" G["maxlag"]
            xmlin = http2var(url)
            xmlout = xmlout "\n" parsexmlucon(xmlin)
            continuecode = getcontinueuc(xmlin)
        }

        return xmlout
}
function getcontinueuc(xmlin,      re,a,b,c) {

        # eg. <continue uccontinue="20160214061737|704890823" continue="-||"/>
        match(xmlin, /uccontinue="[^\"]*"/, a)
        split(a[0], b, "\"")
        if ( length(b[2]) > 0)
            return b[2]
        return 0
}
function parsexmlucon(xmlin,   f,g,e,c,a,i,b,d,out,comment,title,dest1,dest2){

  if(xmlin ~ /error code="maxlag"/) {
    print "Max lag (" G["maxlag"] ") exceeded - aborting. Try again when API servers are less busy, or increase Maxlag (-m)" > "/dev/stderr"
    exit
  }

  f = split(xmlin,e,/<usercontribs>|<\/usercontribs>/)
  c = split(e[2],a,"/>")

  while(++i < c) {
    if(a[i] ~ /[<]item userid[=]/) {
      match(a[i], /title="[^\"]*"/,k) 
      split(gensub("title=","","g",k[0]), g, "\"")
      title = convertxml(g[2])
      match(a[i], /parsedcomment="[^\"]*"/,k)
      comment = gensub("parsedcomment=","","g",k[0])
#      if(comment ~ /Rescuing [0-9]{1,} sources/) {          # Code to optionally process edit comment 
#        out = out title "\n"
#        match(comment, /Rescuing [0-9]{1,} sources/, dest1)
#        match(dest1[0], /[ ][0-9]{1,}[ ]/, dest2)
#        totalc = totalc + strip(dest2[0])
#      }
      out = out title "\n"
    }
  }
  return strip(out)

}

# _____________________________ Backlinks (-b) ______________________________________________

#
# Backlinks main 
#
function backlinks(entity,      url, blinks) {

        # MediaWiki API:Backlinks
        #  https://www.mediawiki.org/wiki/API:Backlinks

        url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" urlencodeawk(entity) "&blredirect&bllimit=250&continue=&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" G["maxlag"]
        blinks = getbacklinks(url, entity, "blcontinue") # normal backlinks

        if ( entity ~ "^Template:") {    # transclusion backlinks
            url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" urlencodeawk(entity) "&continue=&eilimit=500&format=json&utf8=1&maxlag=" G["maxlag"]
            blinks = blinks "\n" getbacklinks(url, entity, "eicontinue")
        } else if ( entity ~ "^File:") { # file backlinks
            url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" urlencodeawk(entity) "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" G["maxlag"]
            blinks = blinks "\n" getbacklinks(url, entity, "iucontinue")
        }

        blinks = uniq(blinks)
        if(length(blinks) > 0)
          print blinks 

        close(outfile)
        return length(blinks)
}
function getbacklinks(url, entity, method,      jsonin, jsonout, continuecode) {

        jsonin = http2var(url)
        jsonout = json2var(jsonin)
        continuecode = getcontinuebl(jsonin, method)

        while ( continuecode ) {

            if ( method == "eicontinue" )
                url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" urlencodeawk(entity) "&eilimit=500&continue=-||&eicontinue=" continuecode "&format=json&utf8=1&maxlag=" G["maxlag"]
            if ( method == "iucontinue" )
                url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" urlencodeawk(entity) "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" G["maxlag"]
            if ( method == "blcontinue" )
                url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" urlencodeawk(entity) "&blredirect&bllimit=250&continue=-||&blcontinue=" continuecode "&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" G["maxlag"]

            jsonin = http2var(url)
            jsonout = jsonout "\n" json2var(jsonin)
            continuecode = getcontinuebl(jsonin, method)
        }

        return jsonout
}
function getcontinuebl(jsonin, method     ,re,a,b,c) {

        # "continue":{"blcontinue":"0|20304297","continue"

        re = "\"continue\"[:][{]\"" method "\"[:]\"[^\"]*\""
        match(jsonin, re, a)
        split(a[0], b, "\"")

        if ( length(b[6]) > 0)
            return b[6]
        return 0
}

# _____________________________ Print wiki text (-w) ______________________________________________

#
# Print wiki text (-w) with the plain text option (-p)
#
function wikitextplain(namewiki,   urlencoded,command,f,r,redirurl,xml,i,c,b,k) {

  # MediaWiki API Extension:TextExtracts
  #  https://www.mediawiki.org/wiki/Extension:TextExtracts

  urlencoded = urlencodeawk(strip(namewiki))
  command = "https://" G["lang"] ".wikipedia.org/w/index.php?title=" urlencoded "&action=raw"
  f = http2var(command)
  if(length(f) < 5) 
    return ""
  if(tolower(f) ~ /[#][ ]{0,}redirect[ ]{0,}[[]/ && G["followredirect"] == "true") {
    match(f, /[#][ ]{0,}[Rr][Ee][^]]*[]]/, r)
    gsub(/[#][ ]{0,}[Rr][Ee][Dd][Ii][^[]*[[]/,"",r[0])
    redirurl = strip(substr(r[0], 2, length(r[0]) - 2))
    command = "https://" G["lang"] ".wikipedia.org/w/api.php?format=xml&action=query&prop=extracts&exlimit=1&explaintext&titles=" urlencodeawk(redirurl) 
    xml = http2var(command)
  }
  else {
    command = "https://" G["lang"] ".wikipedia.org/w/api.php?format=xml&action=query&prop=extracts&exlimit=1&explaintext&titles=" urlencodeawk(namewiki)
    xml = http2var(command)
  }

  if(length(xml) < 5)
    return ""
  else {
    c = split(convertxml(xml), b, "<extract[^>]*>")
    i = 1
    while(i++ < c) {
      k = substr(b[i], 1, match(b[i], "</extract>") - 1)
      return strip(k)
    }
  }
}

function wikitext(namewiki,   urlencoded,command,f,r,redirurl) {

  urlencoded = urlencodeawk(strip(namewiki))
  command = "https://" G["lang"] ".wikipedia.org/w/index.php?title=" urlencoded "&action=raw"
  f = http2var(command)
  if(length(f) < 5) 
    return ""

  if(tolower(f) ~ /[#][ ]{0,}redirect[ ]{0,}[[]/ && G["followredirect"] == "true") {
    match(f, /[#][ ]{0,}[Rr][Ee][^]]*[]]/, r)
    gsub(/[#][ ]{0,}[Rr][Ee][Dd][Ii][^[]*[[]/,"",r[0])
    redirurl = strip(substr(r[0], 2, length(r[0]) - 2))
    command = "https://" G["lang"] ".wikipedia.org/w/index.php?title=" urlencodeawk(redirurl) "&action=raw"
    f = http2var(command)
  }
  if(length(f) < 5)
    return ""
  else
    return f
}

# _____________________________ Utility ______________________________________________

#
# Run a system command and store result in a variable
#   eg. googlepage = sys2var("wget -q -O- http://google.com")
# Supports pipes inside command string. Stderr is sent to null.
# If command fails return null
#
function sys2var(command        ,catch, weight, ship) {

         command = command " 2>/dev/null"
         while ( (command | getline catch) > 0 ) {
             if ( ++weight == 1 )
                 ship = catch
             else
                 ship = ship "\n" catch
         }
         close(command)
         return ship
}

#
# Webpage to variable. url is assumed to be percent encoded.
#
function http2var(url) {

        if(G["wta"] == "wget")
          return sys2var("wget --no-check-certificate --user-agent=\"" G["agent"] "\" -q -O- -- \"" url "\"")
        else if(G["wta"] == "curl")
          return sys2var("curl -L -s -k --user-agent \"" G["agent"] "\" -- \"" url "\"")
        else if(G["wta"] == "lynx")
          return sys2var("lynx -source -- \"" url "\"")
}

#
# Percent encode a string for use in a URL
#  Credit: Rosetta Code May 2015 
#  GNU Awk needs -b to encode extended ascii eg. "ł"
#           
function urlencodeawk(str,  c, len, res, i, ord) {    

        for (i = 0; i <= 255; i++)
                ord[sprintf("%c", i)] = i
        len = length(str)
        res = ""
        for (i = 1; i <= len; i++) {
                c = substr(str, i, 1);
                if (c ~ /[0-9A-Za-z]/)
                        res = res c
                else
                        res = res "%" sprintf("%02X", ord[c])
        }                 
        return res
}

# 
# Convert XML to plain
#
function convertxml(str,   safe) {

      safe = str
      gsub(/&lt;/,"<",safe)
      gsub(/&gt;/,">",safe)
      gsub(/&quot;/,"\"",safe)
      gsub(/&amp;/,"\\&",safe)
      gsub(/&#039;/,"'",safe)
      return safe
}

#
# entity_exists - see if a page on Wikipedia exists
#   eg. if ( ! entity_exists("Gutenberg author") ) print "Unknown page"
#
function entity_exists(entity   ,url,jsonin) {

        url = "https://" G["lang"] ".wikipedia.org/w/api.php?action=query&titles=" urlencodeawk(entity) "&format=json"
        jsonin = http2var(url)
        if(jsonin ~ "\"missing\"")
            return 0
        return 1
}

#
# Uniq a list of \n separated names
#
function uniq(names,    b,c,i,x) {

        c = split(names, b, "\n")
        names = "" # free memory
        while (i++ < c) {
            gsub(/\\["]/,"\"",b[i])
            if(b[i] ~ "for API usage") { # Max lag exceeded.
                print "\nMax lag (" G["maxlag"] ") exceeded - aborting. Try again when API servers are less busy, or increase Maxlag (-m)" > "/dev/stderr"
                exit
            }
            if(b[i] == "")
                continue
            if(x[b[i]] == "")
                x[b[i]] = b[i]
        }
        delete b # free memory
        return join2(x,"\n")
}

#
# Strip leading/trailing whitespace
#
function strip(str) {
  return gensub(/^[[:space:]]+|[[:space:]]+$/,"","g",str)
}

#
# Merge an array of strings into a single string. Array indice are numbers.
#
function join(array, start, end, sep,    result, i) {

    result = array[start]
    for (i = start + 1; i <= end; i++)
        result = result sep array[i]
    return result
}

#
# Merge an array of strings into a single string. Array indice are strings.
#
function join2(arr, sep         ,i,lobster) {

        for ( lobster in arr ) {
            if(++i == 1) {
                result = lobster
                continue
            }
            result = result sep lobster
        }
        return result
}

#
# Return 1 if str is a pure digit
#  eg. "1234" == 1. "0fr123" == 0
#
function isanumber(str,    safe,i) {

  safe = str
  if(safe == "") return 0
  if(safe == "0") return 1
  while( i++ < length(safe) ) {
    if( substr(safe,i,1) !~ /[0-9]/ )
      return 0
  }            
  return 1

}


# =====================================================================================================
# JSON parse function. Returns a list of values parsed from json data.
#   example:  jsonout = json2var(jsonin)
# Returns a string containing values separated by "\n".
# See the section marked "<--" in parse_value() to customize for your application.
#
# Credits: by User:Green Cardamom at en.wikipedia.org
#          JSON parser derived from JSON.awk
#          https://github.com/step-/JSON.awk.git
# MIT license. May 2015        
# =====================================================================================================
function json2var(jsonin) {

        TOKEN=""
        delete TOKENS
        NTOKENS=ITOKENS=0
        delete JPATHS
        NJPATHS=0
        VALUE=""

        tokenize(jsonin)

        if ( parse() == 0 ) {
          return join(JPATHS,1,NJPATHS, "\n")
        }
}
function parse_value(a1, a2,   jpath,ret,x) {
        jpath=(a1!="" ? a1 "," : "") a2 # "${1:+$1,}$2"
        if (TOKEN == "{") {
                if (parse_object(jpath)) {
                        return 7
                }
        } else if (TOKEN == "[") {
                if (ret = parse_array(jpath)) {
                        return ret
        }
        } else if (TOKEN ~ /^(|[^0-9])$/) {
                # At this point, the only valid single-character tokens are digits.
                return 9
        } else {
                VALUE=TOKEN
        }
        if (! (1 == BRIEF && ("" == jpath || "" == VALUE))) {

                # This will print the full JSON data to help in building custom filter
                # x = sprintf("[%s]\t%s", jpath, VALUE)
                # print x

                if ( a2 == "\"*\"" || a2 == "\"title\"" ) {     # <-- Custom filter for MediaWiki API backlinks. Add custom filters here.
                    x = substr(VALUE, 2, length(VALUE) - 2)
                    NJPATHS++
                    JPATHS[NJPATHS] = x
                }

        }
        return 0
}
function get_token() {
        TOKEN = TOKENS[++ITOKENS] # for internal tokenize()
        return ITOKENS < NTOKENS
}
function parse_array(a1,   idx,ary,ret) {
        idx=0
        ary=""
        get_token()
        if (TOKEN != "]") {
                while (1) {
                        if (ret = parse_value(a1, idx)) {
                                return ret
                        }
                        idx=idx+1
                        ary=ary VALUE
                        get_token()
                        if (TOKEN == "]") {
                                break
                        } else if (TOKEN == ",") {
                                ary = ary ","
                        } else {
                                return 2
                        }
                        get_token()
                }
        }
        VALUE=""
        return 0
}
function parse_object(a1,   key,obj) {
        obj=""
        get_token()
        if (TOKEN != "}") {
                while (1) {
                        if (TOKEN ~ /^".*"$/) {
                                key=TOKEN
                        } else {
                                return 3
                        }
                        get_token()
                        if (TOKEN != ":") {
                                return 4
                        }
                        get_token()
                        if (parse_value(a1, key)) {
                                return 5
                        }
                        obj=obj key ":" VALUE
                        get_token()
                        if (TOKEN == "}") {
                                break
                        } else if (TOKEN == ",") {
                                obj=obj ","
                        } else {
                                return 6
                        }
                        get_token()
                }
        }
        VALUE=""
        return 0
}
function parse(   ret) {
        get_token()
        if (ret = parse_value()) {
                return ret
        }
        if (get_token()) {
                return 11
        }
        return 0
}
function tokenize(a1,   myspace) {

        # POSIX character classes (gawk) 
        # Replaced regex constant for string constant, see https://github.com/step-/JSON.awk/issues/1
        myspace="[[:space:]]+"
        gsub(/\"[^[:cntrl:]\"\\]*((\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})[^[:cntrl:]\"\\]*)*\"|-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?|null|false|true|[[:space:]]+|./, "\n&", a1)
        gsub("\n" myspace, "\n", a1)
        sub(/^\n/, "", a1)
        ITOKENS=0 
        return NTOKENS = split(a1, TOKENS, /\n/)

}

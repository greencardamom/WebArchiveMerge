#!/usr/local/bin/gawk -E     

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

  while ((C = getopt(ARGC, ARGV, "hs:p:n:")) != -1) {
      opts++
      if(C == "p")                 #  -p <project>   Use project name. Default in project.cfg
        pid = verifypid(Optarg)
      if(C == "n")                 #  -n <name>      Name to process.
        namewiki = verifyval(Optarg)
      if(C == "s")                 #  -s <file>      article.txt source to process.
        articlename = verifyval(Optarg)

      if(C == "h") {
        usage()
        exit
      }

  }
  if( pid ~ /error/ || ! opts || namewiki == "" || articlename == "" ) {
    usage()
    exit
  }

  setProject(pid)     # library.awk .. load Project[] paths via project.cfg

  main()

}

function main(article,c,i,s,a,j,pa,pc,pan,pp,hold,arg,argfield,field,sep,sep2,sep3,command,api,datetype) {

  checkexists(articlename, "wam.awk main()", "exit")
  article = readfile(articlename)
  datetype = setdatetype(article)  # check for {{dmy}} or {{mdy}} in article

  c = patsplit(article, field, /{[ ]?{[ ]?[Dd]ate[^}]*}[ ]?}/,sep)      # Convert {{date|1 May 2005}} -> ZzPp5|1 May 2005ZzPp6
  while(i++ < c) {
    gsub(/^{[ ]?{[ ]?Date[ ]{1,}[|]/,"ZzPp2",field[i])
    gsub(/^{[ ]?{[ ]?Date[|]/,"ZzPp3",field[i])
    gsub(/^{[ ]?{[ ]?date[ ]{1,}[|]/,"ZzPp4",field[i])
    gsub(/^{[ ]?{[ ]?date[|]/,"ZzPp5",field[i])
    gsub(/}[ ]?}$/,"ZzPp6",field[i])
  }
  if(c > 0) article = unpatsplit(field, sep)
  i = c = 0

  gsub(/{{[=]}}/,"aAkK",article)   # remove magic {{=}} so patsplit can find the end of template
  gsub(/{{[!]}}/,"aAjJ",article)   # remove magic {{!}} (renders as "|" in templates)

  c = patsplit(article, field, /{[ ]?{[ ]?[Ww]ay[Bb]ack[^}]*}[ ]?}|{[ ]?{[ ]?[Ww]ay[Bb]ack[Dd]ate[^}]*}[ ]?}|{[ ]?{[ ]?[Ww]eb[Aa]rchiv[ ]?[|][^}]*}[ ]?}|{[ ]?{[ ]?[Ww]eb[Cc]ite[^}]*}[ ]?}|{[ ]?{[ ]?[Ww]eb[Cc]itation[^}]*}[ ]?}/, sep)

  while(i++ < c ) {
    s = split(field[i], a, "|")
    if(s < 2) continue
    j = 0
    delete hold

    while(j++ < s) {

                                                                 # Parse old templates into hold[] array

      argfield = strip(a[j])
      argfield = stripwikicomments(argfield)
      if(j == 1) {                                               # skip leading "{{wayback"
        hold["service"] = service(argfield)
        continue  
      }        
      arg = getnamedarg(striparg(argfield))
      if(arg == 0) {                                             # positional parameter
        if(j == 2) {
          hold["url"] = striparg(argfield)
          split(hold["url"], pp, " ")
          hold["url"] = strip(pp[1])
        }
        if(j == 3 && hold["service"] == "wayback") {
          hold["title"] = striparg(argfield)
        }
        if(j == 4 && hold["service"] == "wayback") 
          hold["date"] = striparg(argfield)
      }
      else if(arg == "posnumber") {                              # numbered positional parameter (1=, 2=)
        pc = split(argfield, pa, "=")
        if(pc > 1) {
          pan = strip(pa[1])
          if(pan == "1") {
            hold["url"] = striparg(pa[2])
            split(hold["url"], pp, " ")
            hold["url"] = strip(pp[1])
          }
          else if(pan == "2") {
            hold["title"] = striparg(pa[2])            
          }
          else if(pan == "3") {
            hold["date"] = striparg(pa[2])            
          }
        }
      }
      else if(arg == "url") {
        gsub(/^[ ]{0,}[Uu][Rr][Ll][ ]{0,}[=]/,"",argfield)
        hold["url"] = striparg(argfield)      
        split(hold["url"], pa, " ")
        hold["url"] = strip(pa[1])
                                                                  # Fix bugs created by IABot

        if(hold["service"] == "webcite" && hold["url"] ~ /https[:]\/\/web[.]http[:]\/\/www[.]webcitation/)           
          gsub(/^https[:]\/\/web[.]/,"",hold["url"])
        if(hold["service"] == "wayback" && hold["url"] ~ /http[:]\/\/www[.]webcitation[.]org\/query[?]url[=]http/) 
          gsub(/^http[:]\/\/www[.]webcitation[.]org\/query[?]url[=]/,"",hold["url"])

      }
      else if(arg == "wayback") {
        gsub(/^[ ]{0,}[Ww]ayback[ ]{0,}[=]/,"",argfield)
        hold["date"] = striparg(argfield)      
      }
      else if(arg == "date") {
        gsub(/^[ ]{0,}[Dd]ate[ ]{0,}[=]/,"",argfield)
        hold["date"] = striparg(argfield)      
      }
      else if(arg == "dateformat") {
        gsub(/^[ ]{0,}[Dd]ateformat[ ]{0,}[=]/,"",argfield)
        hold["dateformat"] = striparg(argfield)      
      }
      else if(arg == "text") {
        gsub(/^[ ]{0,}[Tt]ext[ ]{0,}[=]/,"",argfield)
        hold["title"] = striparg(argfield)      
      }
      else if(arg == "name") {
        gsub(/^[ ]{0,}[Nn]ame[ ]{0,}[=]/,"",argfield)
        hold["title"] = striparg(argfield)      
      }
      else if(arg == "tutle") {
        gsub(/^[ ]{0,}[Tt]utle[ ]{0,}[=]/,"",argfield)
        hold["title"] = striparg(argfield)      
      }
      else if(arg == "tile") {
        gsub(/^[ ]{0,}[Tt]ile[ ]{0,}[=]/,"",argfield)
        hold["title"] = striparg(argfield)      
      }
      else if(arg == "title") {
        gsub(/^[ ]{0,}[Tt]itle[ ]{0,}[=]/,"",argfield)
        hold["title"] = striparg(argfield)      
      }
      else if(arg == "mf") {
        gsub(/^[ ]{0,}[Mm][Ff][ ]{0,}[=]/,"",argfield)
        hold["df"] = striparg(argfield)      
      }
      else if(arg == "df") {
        gsub(/^[ ]{0,}[Dd][Ff][ ]{0,}[=]/,"",argfield)
        hold["df"] = striparg(argfield)      
      }
      else if(arg == "nolink") {
        gsub(/^[ ]{0,}[Nn]olink[ ]{0,}[=]/,"",argfield)
        hold["nolink"] = striparg(argfield)      
      }
      else if(arg == "quote") {
        gsub(/^[ ]{0,}[Qq]uote[ ]{0,}[=]/,"",argfield)
        hold["quote"] = striparg(argfield)      
      }
    }

    if(hold["date"] ~ /ZzPp2|ZzPp3|ZzPp4|ZzPp5|ZzPp6/) {          # Try to untangle embedded {{date}} subarguments
      gsub(/ZzPp2|ZzPp3|ZzPp4|ZzPp5|ZzPp6/,"",hold["date"])
      if(hold["date"] ~ /mdy|MDY/) {
        hold["date"] = ""
        hold["dateformat"] = "mdy"
      }
      else if(hold["date"] ~ /dmy|DMY/) {
        hold["date"] = ""
        hold["dateformat"] = "dmy"
      }
      else if(hold["date"] ~ /iso|ISO/) {
        hold["date"] = ""
        hold["dateformat"] = "iso"
      }
      else if(hold["date"] ~ /ymd|YMD/) {
        hold["date"] = ""
        hold["dateformat"] = "ymd"
      }
      else if(hold["date"] ~ /none/) {
        hold["date"] = ""
      }
      else if(hold["date"] ~ /[|]/)
        hold["date"] = ""
    }

                                                                 # Build new webarchive template

    hold["webarchivetitle"] = hold["title"]
    hold["webarchivenolink"] = hold["nolink"]


    if(hold["service"] == "wayback") {

      if(hold["date"] == "") {  # Date missing. Get nearest available date from Wayback API
        command = "wget --header=\"Wayback-Api-Version: 2\" --post-data=\"url=" hold["url"] "&closest=before&statuscodes=200&statuscodes=203&statuscodes=206&tag=&timestamp=20070101\" -q -O- \"http://archive.org/wayback/available\""
        api = sys2var(command)
        match(str, /(.*)(timestamp["][:] ["][^"]*["])(.*)/,sep2)
        if(sep2[2] !~ /"20070101"/) {
          split(sep2[2], sep3,/["]/)
          hold["date"] = sep3[3]
        }
      }

      if(hold["date"] == "")  # Date missing. Default to "*" index
        hold["date"] = "*"

      hold["webarchiveurl"] = "https://web.archive.org/web/" hold["date"] "/" hold["url"]

      if(hold["date"] == "*") hold["webarchivedate"] = "*"
      fullnumber = substr(strip(hold["date"]),1,8)                               # 20160901
      if(isanumber(fullnumber)) {
        yeardigit = substr(fullnumber,1,4)                                       # 2016
        monthdigitz = monthdigit = substr(fullnumber,5,2)                        # 01
        daydigitz = daydigit = substr(fullnumber,7,3)                            # 09
        gsub(/^0/,"",monthdigit)                                                 # 1
        gsub(/^0/,"",daydigit)                                                   # 9
        monthname = digit2month(monthdigit)                                      # January

        if(length(fullnumber) == 4) hold["webarchivedate"] = yeardigit
        else if(length(fullnumber) == 6) hold["webarchivedate"] = monthname " " yeardigit 
        else if(length(fullnumber) > 7) {
          if(hold["df"] ~ /[Yy][Ee]?[Ss]?/ || hold["df"] ~ /[Dd][Mm][Yy]/ || (datetype == "dmy" && hold["df"] == "" ) ) 
            hold["webarchivedate"] = daydigit " " monthname " " yeardigit        # dmy
          else if(hold["df"] ~ /[Nn][Oo]?/ || hold["df"] ~ /[Mm][Dd][Yy]/ )
            hold["webarchivedate"] = monthname " " daydigit ", " yeardigit       # mdy
          else if(hold["df"] ~ /[Ii][Ss][Oo]/ )
            hold["webarchivedate"] = yeardigit "-" monthdigitz "-" daydigitz     # iso
          else
            hold["webarchivedate"] = monthname " " daydigit ", " yeardigit       # mdy (default)
        }
      }
    }

    else if(hold["service"] == "webcite") {            

      hold["webarchiveurl"] = webciteurl(hold["url"])

      if(hold["dateformat"] !~ /[Mm][Dd][Yy]|[Dd][Mm][Yy]|[Ii][Ss][Oo]|[Yy][Mm][Dd]/) 
        hold["dateformat"] = datetype

      pc = split(uriparseElement(hold["url"],"path"),pa,"/")
      if(pc > 1) {
        if(pa[2] ~ /query/)
          hold["webarchivedate"] = hold["date"]
        else {
          hold["webciteid"] = strip(pa[2])
          command = Exe["base62"] " \"" hold["webciteid"] "\""
          rawdate = sys2var(command)
          if(rawdate == "error") {
            hold["webarchivedate"] = hold["date"]
          }
          else {
            pc = split(rawdate,pa,"|")
            if(pc == 4) {
              if(hold["dateformat"] ~ /[Mm][Dd][Yy]/) 
                hold["webarchivedate"] = strip(pa[1])
              else if(hold["dateformat"] ~ /[Dd][Mm][Yy]/) 
                hold["webarchivedate"] = strip(pa[2])
              else if(hold["dateformat"] ~ /[Ii][Ss][Oo]/) 
                hold["webarchivedate"] = strip(pa[3])
              else if(hold["dateformat"] ~ /[Yy][Mm][Dd]/) 
                hold["webarchivedate"] = strip(pa[4])
              else {
                hold["webarchivedate"] = hold["date"]
              }
            }
            else {
              hold["webarchivedate"] = hold["date"]
            }
          }
        }
      }
      else {
        hold["webarchivedate"] = hold["date"]
      }
    }

# print field[i]

    sand = "{{webarchive |url=" hold["webarchiveurl"]
    if(length(hold["webarchivedate"]) > 0) 
      sand = sand " |date=" hold["webarchivedate"]
    if(length(hold["webarchivetitle"]) > 0) 
      sand = sand " |title=" hold["webarchivetitle"]
    if(length(hold["webarchivenolink"]) > 0) 
      sand = sand " |nolink="
    sand = sand " }}" 
    if(length(hold["quote"]) > 0)
      sand = sand " Quote: " hold["quote"]

    field[i] = sand
  }

  articlenew = unpatsplit(field, sep)

  if(article != articlenew && length(articlenew) > 10 && c > 0) {
   
    gsub(/aAjJ/, "{{!}}", articlenew)  # restore {{!}} 
    gsub(/aAkK/, "{{=}}", articlenew)  # restore {{=}} 
    gsub(/ZzPp6/, "}}", articlenew)    # restore {{date..}} 
    gsub(/ZzPp2/, "{{Date |", articlenew)     
    gsub(/ZzPp3/, "{{Date|", articlenew)     
    gsub(/ZzPp4/, "{{date |", articlenew)     
    gsub(/ZzPp5/, "{{date|", articlenew)     

    articlenewname = editsummaryname = articlename

    gsub(/article.txt$/, "article.new.txt", articlenewname) 
    printf("%s", articlenew) > articlenewname 
    close(articlenewname)

    gsub(/article.txt$/, "editsummary", editsummaryname) 
    templates = "templates"
    if(c == 1) templates = "template"
    printf("%s archive %s merged to {{[[template:webarchive|webarchive]]}} ([[User:Green_Cardamom/Webarchive_template_merge|WAM]])",c,templates) > editsummaryname
    close(editsummaryname)

    print c

  }

  exit

}


function unpatsplit(field,sep,   c,o) {

  if(length(field) > length(sep)) return 

  o = sep[0]
  c = 1
  while(c < length(field) + 1) {
#    print "field[" c "] = " field[c] 
#    print "sep[" c "] = " sep[c] 
    o = o field[c] sep[c] 
    c++
  }

  return o

}

function getnamedarg(str) {


  if(str ~ /^[ ]{0,}[Dd][Ff][ ]{0,}[=]/) return "df"
  if(str ~ /^[ ]{0,}[Mm][Ff][ ]{0,}[=]/) return "mf"
  if(str ~ /^[ ]{0,}[Dd]ate[ ]{0,}[=]/) return "date"
  if(str ~ /^[ ]{0,}[Uu][Rr][Ll][ ]{0,}[=]/) return "url"
  if(str ~ /^[ ]{0,}[Dd]ateformat[ ]{0,}[=]/) return "dateformat"
  if(str ~ /^[ ]{0,}[Tt]utle[ ]{0,}[=]/) return "tutle"
  if(str ~ /^[ ]{0,}[Tt]itle[ ]{0,}[=]/) return "title"
  if(str ~ /^[ ]{0,}[Tt]ile[ ]{0,}[=]/) return "tile"
  if(str ~ /^[ ]{0,}[Nn]ame[ ]{0,}[=]/) return "name"
  if(str ~ /^[ ]{0,}[Tt]ext[ ]{0,}[=]/) return "text"
  if(str ~ /^[ ]{0,}[Ww]ayback[ ]{0,}[=]/) return "wayback"
  if(str ~ /^[ ]{0,}[Nn]olink[ ]{0,}[=]/) return "nolink"
  if(str ~ /^[ ]{0,}[Qq]uote[ ]{0,}[=]/) return "quote"

  if(str ~ /^[ ]{0,}[Bb][Oo][Tt][ ]{0,}[=]/) return "bot"
  if(str ~ /^[ ]{0,}[Aa]ccess[-]?date[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Dd]ead[-]?url[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Aa]rchive[-]?url[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Aa]rchive[-]?date[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Pp]ublisher[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Aa]uthor[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Ll]anguage[ ]{0,}[=]/) return "unknown"
  if(str ~ /^[ ]{0,}[Ww]ork[ ]{0,}[=]/) return "unknown"

  if(str ~ /^[ ]{0,}[0-9]{0,}[=]/) return "posnumber"

  if(str ~ /^[^=]*[=]/) {            # positional parameter contains {{=}} make a best guess of type
    if(str ~ /^http/) return "url"
  }
   
  return 0

}

#
# Given the leading part of a template, return if it's wayback or webcite
#
function service(str) {

  if(str ~ /[Ww]ay[Bb]ack|[Ww]ay[Bb]ack[Dd]ate|[Ww]eb[Aa]rchiv/) return "wayback"
  if(str ~ /[Ww]eb[Cc]ite|[Ww]eb[Cc]itation/) return "webcite"
  return "unknown"

}

#
# Given an argument fragment, strip any extra stuff 
#
function striparg(str) {

  str = stripwikicomments(str)
  sub(/[}]{1}[}]{1}$/,"",str)
  str = strip(str)

  return str

}

function digit2month(n) {

  if(n == 1) return "January"
  else if(n == 2) return "February"
  else if(n == 3) return "March"
  else if(n == 4) return "April"
  else if(n == 5) return "May"
  else if(n == 6) return "June"
  else if(n == 7) return "July"
  else if(n == 8) return "August"
  else if(n == 9) return "September"
  else if(n == 10) return "October"
  else if(n == 11) return "November"
  else if(n == 12) return "December"

}

#
# Given a URL, urldecode certain characters
#
function decodeurl(url) {
        gsub(/%2[Ff]/,"/",url)
        gsub(/%3[Aa]/,":",url)
        gsub(/%3[Ff]/,"?",url)
        return url
}

#
# Given a webcite URL, return in long format urlencoded
#  eg. http://www.webcitation.org/65yd5AgqG?url=http%3A//www.infodisc.fr/S_Certif.php
#
#  If url is short-form (eg. http://www.webcitation.org/65yd5AgqG) determine long form via API
#
function webciteurl(url,  pa,pc,id) {

      if(url ~ /webcitation[.]org\/[^?]*[?]url[=]/)    # Already long format
        return decodeurl(url)

      pc = split(uriparseElement(url,"path"),pa,"/")          
      if(pc > 1) { 
        if(pa[2] ~ /query/)
          return url
        id = strip(pa[2]) 
        xml = http2var("http://www.webcitation.org/query?id=" id "&returnxml=true")
        match(xml,/<original_url>[^<]*<\/original_url>/,origurl)
        gsub(/<original_url>/,"",origurl[0])
        gsub(/<\/original_url>/,"",origurl[0])
        match(xml,/<redirected_to_url>[^<]*<\/redirected_to_url>/,redirurl)
        gsub(/<redirected_to_url>/,"",redirurl[0])
        gsub(/<\/redirected_to_url>/,"",redirurl[0])
     
        if(length(origurl[0]) == 0 && length(redirurl[0]) > 0)
          xurl = redirurl[0]
        else if(length(origurl[0]) > 0)
          xurl = origurl[0]
        else
          return url

        # Don't encode / : ? but everything else
        # <space> encoded as %20 not + 
        # webcitation.org ignores the content of ?url= if there is a base-62 ID

        return "http://www.webcitation.org/" id "?url=" decodeurl(urlencodepython(urldecodepython(xurl)))

        
      }

      return url
}

#
# Determine date type - set global Datetype = dmy or mdy
#   default mdy
#    
function setdatetype(article) {
  if(article ~ /[{]{0,}[{][ ]{0,}[Uu]se[ ][Dd][Mm][Yy][ ]?[Dd]?a?t?e?s?|[{]{0,}[{][ ]{0,}[Dd][Mm][Yy]|[{]{0,}[{][ ]{0,}[Uu][Ss][Ee][Dd][Mm][Yy]/)
    return "dmy"
  return "mdy"
}

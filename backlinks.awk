#!/usr/local/bin/gawk -E

# backlinks.awk
#  -- demonstration program of the MediaWiki Awk API Library.
#
#  Prints the full list of backlinks such as seen at "Special:What Links Here"
#   * It uses the "continue" function (not limited by 500 results).
#   * It includes (transcluded) pages for Templates.
#   * It includes second-level backlinks (from redirects)
#

@include "json2var.awk"
@include "mwapi.awk"
@include "json-parser.awk"

@include "getopt.awk"

BEGIN {

        while ((C = getopt(ARGC, ARGV, "he:")) != -1) {
          opts++
          if(C == "e")                 #  -e <name>      Entity to process. eg. "Template:Wayback"
            entity = verifyval(Optarg)
          if(C == "h") {
            usage()
            exit
           }
        }
        if( entity ~ /error/ || ! opts || entity == "" ) {
          usage()
          exit
        }

        Agent = "Backlinks.awk - User:Green_Cardamom"

	if ( entity_exists(entity) ) {
	    if ( ! backlinks(entity) ) 
                print "No backlinks for " entity
        }
}

function backlinks(entity	,url, method, jsonin, jsonout, continuecode, b, c, i, x) {

        gsub(" ","_",entity)

        if ( entity ~ /^Template[:]|^Module[:]/) {
            method = "eicontinue"  # transcluded links
            url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" entity "&continue=&eilimit=500&format=json&utf8=1&maxlag=5"
        } else if ( entity ~ "^File:") {
            method = "iucontinue"  # file links
            url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" entity "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=5"
        } else {
            method = "blcontinue"  # normal links
            url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" entity "&blredirect&bllimit=250&continue=&blfilterredir=nonredirects&format=json&utf8=1&maxlag=5"
        }

        jsonin = http2var(url)
        split(jsonin,a,"([[]|[]])") # json parser doesn't support [] arrays
        error = parseJson(a[2], tx, keys)
        if (error) {
            print error
            print "Unable to parse JSON"
        } else {
            for(z in keys) {
              if(keys[z] ~ "title") {
                jsonout = jsonout "\n" tx[keys[z]] 
              }
            }
        }
        jsonout = json2var(jsonin)
        continuecode = getcontinue(jsonin, method)

        while ( continuecode ) {

            if ( method == "eicontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" entity "&eilimit=500&continue=-||&eicontinue=" continuecode "&format=json&utf8=1&maxlag=5"
            if ( method == "iucontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" entity "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=5"
            if ( method == "blcontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" entity "&blredirect&bllimit=250&continue=-||&blcontinue=" continuecode "&blfilterredir=nonredirects&format=json&utf8=1&maxlag=5"

            jsonin = http2var(url)
            jsonout = jsonout "\n" json2var(jsonin)
            continuecode = getcontinue(jsonin, method)
        }

       # Uniq the list of names since the API returns duplicates (by design *sigh*) when using &blredirect
        c = split(jsonout, b, "\n")
        jsonout = ""
        while (i++ < c) {
            if(b[i] ~ "for API usage") # intermittent bug; MediaWiki returns "See https://en.wikipedia.org/w/api.php for API usage" instead of backlinks
                continue
            if(x[b[i]] == "")
                x[b[i]] = b[i]
        }
        delete b
        jsonout = join2(x,"\n")

        if ( length(jsonout) > 0 )
          print jsonout 
        return length(jsonout)

}

function getcontinue(jsonin, method     ,re,a,b,c) {

        # eg. "continue":{"blcontinue":"0|20304297","continue"

        re = "\"continue\"[:][{]\"" method "\"[:]\"[^\"]*\""
        match(jsonin, re, a)
        split(a[0], b, "\"")

        if ( length(b[6]) > 0)
            return b[6]
        return 0
}


# 
# Verify any argument has valid value                
#
function verifyval(val) {
  if(val == "" || substr(val,1,1) ~/^[-]/) {
    print "Command line argument has an empty value when it should have something." > "/dev/stderr"
    exit
  }
  return val
}              

function usage() {

  print "Something's wrong with the arguments. See backlinks.awk for usage info."
  exit

}

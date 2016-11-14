WebArchiveMerge bot
===================
WebArchiveMerge is a Wikipedia bot to merge multiple templates into a single template.

Example edit: https://en.wikipedia.org/w/index.php?title=Chadstone_High_School&diff=prev&oldid=749418640

Bot info page: https://en.wikipedia.org/wiki/User:Green_Cardamom/Webarchive_template_merge

by User:Green Cardamom (en.wikipedia.org)
November 2016
MIT License

Source
========
GNU Awk 4.1

The core functionality is wam.awk which processes a single article.

driver.awk "drives" (executes) wam, which in turn is executed by GNU Parallel in batches

project.awk is a tool for creating and managing batches of articles for processing by driver

Install and operate
==================
See 0README

Credits
==================
Want to use MediaWiki API with Awk? Check out 'MediaWiki Awk API Library'
https://github.com/greencardamom/MediaWikiAwkAPI



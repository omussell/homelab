---
title: "Building static sites with Hugo"
date: 2018-01-25T22:31:45Z
draft: false
---

Install hugo

```
# note 'hugo' is not the right package. It is completely different and 
# will take a long time to download before you realise its the wrong thing.
pkg install -y gohugo git
```

Run `hugo` in the directory to build the assets, which will be placed into the public directory. 

Run `hugo server --baseUrl=/ --port=1313 --appendPort=false`

Note that the baseURL is /. This is because it wasn't rendering the css at all when I used a server name or IP address. In production, this should be the domain name of the website followed by a forward slash.

You can then visit your server at port 1313. 

For the baseUrl when using github pages, you should use the repo name surrounded by slashes, like /grim/.

Themes can be viewed at themes.gohugo.io. They usually have instructions on how to use it.

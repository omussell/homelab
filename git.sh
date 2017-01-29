PWD=`pwd`
pandoc -o ~/www/index.html ~/www/index.md
pandoc -s -S -c /design/style.css --toc ~/www/design/designdoc.txt -o ~/www/design/index.html
cd ~/www
git add --all
git commit -m "Updated index.html"
git push -u origin gh-pages
cd $PWD

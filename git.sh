PWD=`pwd`
<<<<<<< HEAD
pandoc -o ~/www/index.html ~/www/index.md
pandoc -s -S -c /design/style.css --toc ~/www/design/designdoc.txt -o ~/www/design/index.html
cd ~/www
=======
pandoc -o ~/www/homelab/index.html ~/www/homelab/index.md
pandoc -s -S -c /homelab/design/style.css --toc ~/www/homelab/design/designdoc.txt -o ~/www/homelab/design/index.html
cd ~/www/homelab
>>>>>>> 75ca7bc9611273ab6ae01d0e1502dea51598f599
git add --all
git commit -m "Updated index.html"
git push -u origin gh-pages
cd $PWD

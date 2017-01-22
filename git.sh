pandoc -o ~/www/homelab/index.html ~/www/homelab/index.md
pandoc -s -S -c /homelab/design/style.css --toc ~/www/homelab/design/designdoc.txt -o ~/www/homelab/design/index.html
cd ~/www/homelab
git add --all
git commit -m "Updated index.html"
git push -u origin gh-pages

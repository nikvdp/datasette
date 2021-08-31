# following https://github.com/simonw/datasette/issues/93#issuecomment-754219002
conda create -n datasette python=3
pip install wheel datasette pyinstaller

export DATASETTE_BASE=$(python -c 'import os; print(os.path.dirname(__import__("datasette").__file__))')

pyinstaller -F \
    --add-data "$DATASETTE_BASE/templates:datasette/templates" \
    --add-data "$DATASETTE_BASE/static:datasette/static" \
    --hidden-import datasette.publish \
    --hidden-import datasette.publish.heroku \
    --hidden-import datasette.publish.cloudrun \
    --hidden-import datasette.facets \
    --hidden-import datasette.sql_functions \
    --hidden-import datasette.actor_auth_cookie \
    --hidden-import datasette.default_permissions \
    --hidden-import datasette.default_magic_parameters \
    --hidden-import datasette.blob_renderer \
    --hidden-import datasette.default_menu_links \
    --hidden-import uvicorn \
    --hidden-import uvicorn.logging \
    --hidden-import uvicorn.loops \
    --hidden-import uvicorn.loops.auto \
    --hidden-import uvicorn.protocols \
    --hidden-import uvicorn.protocols.http \
    --hidden-import uvicorn.protocols.http.auto \
    --hidden-import uvicorn.protocols.websockets \
    --hidden-import uvicorn.protocols.websockets.auto \
    --hidden-import uvicorn.lifespan \
    --hidden-import uvicorn.lifespan.on \
    $(which datasette)

# --- above worked, but the resultant binary wasn't particularly useful (web server started right up, but the 
# `select sqlite_version()` failed with the following:
#         Traceback (most recent call last):
#           File "datasette/app.py", line 1182, in route_path
#           File "datasette/views/base.py", line 149, in view
#           File "datasette/views/base.py", line 124, in dispatch_request
#           File "datasette/views/base.py", line 261, in get
#           File "datasette/views/base.py", line 622, in view_get
#           File "datasette/views/base.py", line 140, in render
#           File "datasette/app.py", line 922, in render_template
#           File "jinja2/environment.py", line 1325, in render_async
#           File "jinja2/environment.py", line 925, in handle_exception
#           File "jinja2/environment.py", line 1323, in <listcomp>
#           File "/var/folders/dv/gmmkzchd5w73p8w2yl4bqbm80000gn/T/_MEI6g6qSW/datasette/templates/query.html", line 1, in top-level templat
#         e code
#             {% extends "base.html" %}
#           File "/var/folders/dv/gmmkzchd5w73p8w2yl4bqbm80000gn/T/_MEI6g6qSW/datasette/templates/base.html", line 56, in top-level templat
#         e code
#             {% block content %}
#           File "/var/folders/dv/gmmkzchd5w73p8w2yl4bqbm80000gn/T/_MEI6g6qSW/datasette/templates/query.html", line 36, in block 'content'
#             <h3>Custom SQL query{% if display_rows %} returning {% if truncated %}more than {% endif %}{{ "{:,}".format(display_rows|leng
#         th) }} row{% if display_rows|length == 1 %}{% else %}s{% endif %}{% endif %}{% if not query_error %} <span class="show-hide-sql">
#         {% if hide_sql %}(<a href="{{ path_with_removed_args(request, {'_hide_sql': '1'}) }}">show</a>){% else %}(<a href="{{ path_with_a
#         dded_args(request, {'_hide_sql': '1'}) }}">hide</a>){% endif %}</span>{% endif %}</h3>
#           File "jinja2/utils.py", line 84, in from_obj
#         jinja2.exceptions.UndefinedError: 'path_with_added_args' is undefined
# 
# I suspect it's got something to do with pyinstaller's path mainpulations. trying with conda-pack instead


conda create -n datasette python=3
conda install conda-pack
conda activate datasette
pip install wheel datasette pyinstaller
conda-pack
mv datasette.tar.gz ~/tmp
cd ~/tmp
mkdir datasette
tar -C datasette -xvzf datasette.tar.gz
export PATH=$PWD/datasette/bin:$PATH

datasette
 
# now the query works. let's see if we can sfx with it warp 

# download warp
# mac: https://github.com/dgiagio/warp/releases/download/v0.3.0/macos-x64.warp-packer
# lin: https://github.com/dgiagio/warp/releases/download/v0.3.0/linux-x64.warp-packer
arch="$(uname | sed 's/Darwin/macos/' | sed 's/Linux/linux/')-x64"
url="https://github.com/dgiagio/warp/releases/download/v0.3.0/$arch.warp-packer" 

wget "$url" -O ./warp-packer
chmod +x ./warp-packer

# we need to write a little launcher script to run datasette with the bundled python interpreter
cat > datasette/bin/launch.sh <<'EOF'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
exec "$SCRIPT_DIR/python" "$SCRIPT_DIR/datasette"
EOF

# # cat datasette/bin/launch.sh
# # chmod +x datasette/bin/launch.sh
# # datasette/bin/launch.sh

./warp-packer --arch "$arch" --input_dir datasette --exec bin/launch.sh --output datasette.bin

./datasette.bin

# cool, this version runs and unlike the sql query version that pyinstaller call actually works

# now let's do electron


# build lib for Lua 5.3

## cjson

git clone https://github.com/mpx/lua-cjson.git

cd lua-cjson

gcc -c fpconv.c strbuf.c lua_cjson.c

gcc -o cjson.dll lua_cjson.o fpconv.o strbuf.o -Wall -O2 -shared lua53.dll


## cmsgpack

git clone https://github.com/antirez/lua-cmsgpack.git

cd lua-cmsgpack

gcc -c lua_cmsgpack.c

gcc -o cmsgpack.dll lua_cmsgpack.o  -Wall -O2 -shared lua53.dll


## lpeg

gcc -c lpvm.c lptree.c lpprint.c lpcode.c lpcap.c

gcc -o lpeg.dll lpvm.o lptree.o lpprint.o lpcode.o lpcap.o -Wall -O2 -shared lua53.dll
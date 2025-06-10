FROM emscripten/emsdk:4.0.9 AS engine

RUN dpkg --add-architecture i386
RUN apt update && apt upgrade -y && apt -y --no-install-recommends install aptitude
RUN aptitude -y --without-recommends install git ca-certificates build-essential gcc-multilib g++-multilib libsdl2-dev:i386 libfreetype-dev:i386 libopus-dev:i386 libbz2-dev:i386 libvorbis-dev:i386 libopusfile-dev:i386 libogg-dev:i386
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

WORKDIR /xash3d-fwgs
COPY xash3d-fwgs .
ENV EMCC_CFLAGS="-s USE_SDL=2"
RUN EMSCRIPTEN=true emconfigure ./waf configure --enable-stbtt --enable-emscripten && \
	emmake ./waf build

COPY patches patches
RUN sed -e '/var Module = typeof Module != "undefined" ? Module : {};/{r patches/head-cs.js' -e 'd}' -i build/engine/index.js
RUN sed -e '/filename = PATH.normalize(filename);/{r patches/filename.js' -e 'd}' -i build/engine/index.js
RUN sed -e 's/run();//g' -i build/engine/index.js
RUN sed -e 's/readFile(path, opts = {}) {/readFile(path, opts = {}) {console.log({path});/g' -i build/engine/index.js
RUN sed -e '/preInit();/{r patches/init.js' -e 'd}' -i build/engine/index.js
RUN sed -e 's/async type="text\/javascript"/defer type="module"/' -i build/engine/index.html


FROM emscripten/emsdk:4.0.9 AS tf

RUN dpkg --add-architecture i386
RUN apt update && apt upgrade -y && apt -y --no-install-recommends install aptitude
RUN aptitude -y --without-recommends install git ca-certificates build-essential gcc-multilib g++-multilib libsdl2-dev:i386 libfreetype-dev:i386 libopus-dev:i386 libbz2-dev:i386 libvorbis-dev:i386 libopusfile-dev:i386 libogg-dev:i386
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

WORKDIR /tf
COPY tf15-client .
ENV EMCC_CFLAGS="-s USE_SDL=2"
RUN emcmake cmake -S . -B build && \
	cmake --build build --config Release


FROM nginx:alpine3.21 AS server

COPY --from=tf /tf/build/3rdparty/mainui_cpp/menu.wasm /usr/share/nginx/html/menu
COPY --from=tf /tf/build/cl_dll/client.wasm /usr/share/nginx/html/client.wasm
COPY --from=tf /tf/build/dlls/tfc.wasm /usr/share/nginx/html/server.wasm
COPY --from=engine /xash3d-fwgs/build/engine/index.html /usr/share/nginx/html/index.html
COPY --from=engine /xash3d-fwgs/build/engine/index.js /usr/share/nginx/html/index.js
COPY --from=engine /xash3d-fwgs/build/engine/index.wasm /usr/share/nginx/html/index.wasm
COPY --from=engine /xash3d-fwgs/build/filesystem/filesystem_stdio.so /usr/share/nginx/html/filesystem_stdio
COPY --from=engine /xash3d-fwgs/build/ref/gl/libref_gles3compat.so /usr/share/nginx/html/ref_gles3compat.so
COPY --from=engine /xash3d-fwgs/build/ref/soft/libref_soft.so /usr/share/nginx/html/ref_soft.so

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

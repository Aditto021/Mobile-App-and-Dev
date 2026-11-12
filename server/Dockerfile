# FeriWala API — container for any Docker host (Render, Railway, Fly.io…).
# Build from the app folder (it needs the catalogue in assets/):
#   docker build -f server/Dockerfile -t feriwala-api .
#   docker run -p 8090:8090 -v feriwala-data:/data feriwala-api
FROM dart:stable AS build
WORKDIR /src/server
COPY server/pubspec.yaml server/pubspec.lock ./
RUN dart pub get
COPY server/ ./
RUN dart pub get --offline && dart compile exe bin/server.dart -o /out/feriwala-api

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /out/feriwala-api /app/feriwala-api
COPY assets/data/products.json /app/products.json
ENV PORT=8090 DATA_PATH=/data/db.json CATALOGUE_PATH=/app/products.json
EXPOSE 8090
# Keep /data on a persistent disk: accounts and orders live there.
VOLUME ["/data"]
CMD ["/app/feriwala-api"]

FROM golang:1.14

WORKDIR /go/src/smartview
COPY . .

RUN go get -d -v ./...
RUN go install -v ./...

EXPOSE 8080

CMD ["/go/bin/main"]

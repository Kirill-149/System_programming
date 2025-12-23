# Makefile для FASM проекта
FASM = fasm

all: server client

server: server.asm
	$(FASM) server.asm
	chmod +x server

client: client.asm
	$(FASM) client.asm
	chmod +x client

clean:
	rm -f server client *.o

run_server: server
	./server

run_client: client
	./client

.PHONY: all clean run_server run_client

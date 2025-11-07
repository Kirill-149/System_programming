asm: queue.asm
	fasm queue.asm

c: asm main.c
	gcc main.c queue.o -o queue

run: c
	./queue

clean:
	rm -f *.o queue

package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"strings"
)

func main() {
	p := make([]byte, 2048)
	conn, err := net.Dial("udp", "127.0.0.1:1234")
	if err != nil {
		fmt.Printf("Some error %v", err)
		return
	}

	fmt.Fprintf(conn, "Hi UDP Server")

	channel := make(chan interface{}, 1)

	go func(in chan interface{}) {

		for {
			_, err = bufio.NewReader(conn).Read(p)
			if err == nil {
				fmt.Printf("%s\n", p)
				in <- p
			} else {
				fmt.Printf("Some error %v\n", err)
			}
		}

	}(channel)

	enterdesWords := ""

	go func() {
		for {
			fmt.Fscan(os.Stdin, &enterdesWords)
			fmt.Println(enterdesWords)
		}

	}()

	for {
		select {
		case recievedMessage := <-channel:

			str := string(recievedMessage.([]uint8))

			if strings.Contains(str, "I need your message") {
				fmt.Println(enterdesWords)
				if len(enterdesWords) < 1 {
					continue
				}
				fmt.Fprintf(conn, "_MY_KEY:"+string(enterdesWords[len(enterdesWords)-1]))
			}
		default:
			continue
		}
	}

	conn.Close()
}

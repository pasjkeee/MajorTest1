package main

import (
	"fmt"
	"net"
	"os"
	"strings"
)

func sendRequest(conn *net.UDPConn, addr *net.UDPAddr) {
	_, err := conn.WriteToUDP([]byte("I need your message"), addr)
	if err != nil {
		fmt.Printf("Couldn't send request %v", err)
	}
}

func sendResponse(conn *net.UDPConn, addr *net.UDPAddr) {
	_, err := conn.WriteToUDP([]byte("From server: Hello I got your message "), addr)
	if err != nil {
		fmt.Printf("Couldn't send response %v", err)
	}
}

type Client struct {
	addr *net.UDPAddr
	key  string
}

func main() {
	p := make([]byte, 2048)
	addr := net.UDPAddr{
		Port: 1234,
		IP:   net.ParseIP("127.0.0.1"),
	}
	ser, err := net.ListenUDP("udp", &addr)
	if err != nil {
		fmt.Printf("Some error %v\n", err)
		return
	}

	clinets := make([]Client, 0, 1024)

	enteredCmd := ""

	go func() {
		for {
			fmt.Fscan(os.Stdin, &enteredCmd)

			if enteredCmd == "get" {
				for _, client := range clinets {
					fmt.Println("Request sended")
					sendRequest(ser, client.addr)
				}
			}

			if enteredCmd == "give" {
				fmt.Println("My list")
				fmt.Println("==========================")
				for _, client := range clinets {
					fmt.Printf("Port: %d Key: %s \n", client.addr.Port, client.key)
				}
				fmt.Println("==========================")
			}
		}
	}()

	for {
		_, remoteaddr, err := ser.ReadFromUDP(p)
		fmt.Printf("Read a message from %v %s \n", remoteaddr, p)

		if err != nil {
			fmt.Printf("Some error  %v", err)
			continue
		}

		if strings.Contains(string(p), "_MY_KEY") {
			for i, client := range clinets {
				if client.addr.Port == remoteaddr.Port {
					clinets[i] = Client{
						addr: client.addr,
						key:  string(strings.Split(string(p), "Y:")[1][0]),
					}
				}
			}
		}

		isChecked := false

		for _, client := range clinets {
			if client.addr.Port == remoteaddr.Port {
				isChecked = true
			}
		}

		if !isChecked {
			clinets = append(clinets, Client{
				addr: remoteaddr,
			})
		}

		go sendResponse(ser, remoteaddr)
	}
}

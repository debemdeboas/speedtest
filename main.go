package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os/exec"
	"sync"
	"time"
)

type Container struct {
	mu     sync.Mutex
	result *SpeedtestResult
}

func (c *Container) Set(result *SpeedtestResult) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.result = result
}

func (c *Container) Get() *SpeedtestResult {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.result == nil {
		return &SpeedtestResult{
			Download:  0,
			Upload:    0,
			Ping:      0,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		}
	}

	return c.result
}

type SpeedtestResult struct {
	Download  float64 `json:"download"`
	Upload    float64 `json:"upload"`
	Ping      float64 `json:"ping"`
	Timestamp string  `json:"timestamp"`
}

func NewSpeedtestResult() *SpeedtestResult {
	cmd := exec.Command("speedtest", "--accept-license", "--accept-gdpr", "-fjson")
	// Read output
	stdout, err := cmd.Output()
	if err != nil {
		fmt.Println(err.Error())
		panic(err)
	}
	var output map[string]any
	if err := json.Unmarshal(stdout, &output); err != nil {
		fmt.Println(err)
		panic(err)
	}

	return &SpeedtestResult{
		Download:  output["download"].(map[string]any)["bandwidth"].(float64),
		Upload:    output["upload"].(map[string]any)["bandwidth"].(float64),
		Ping:      output["ping"].(map[string]any)["latency"].(float64),
		Timestamp: output["timestamp"].(string),
	}
}

func main() {
	c := &Container{}
	go func() {
		for {
			result := NewSpeedtestResult()
			c.Set(result)
			time.Sleep(5 * time.Minute)
		}
	}()

	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		result := c.Get()
		json.NewEncoder(w).Encode(result)
	})

	http.ListenAndServe(":80", nil)
}

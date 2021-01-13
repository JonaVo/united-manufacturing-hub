package internal

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"strconv"
	"sync"
	"time"
)

var lock sync.Mutex

// Marshal is a function that marshals the object into an
// io.Reader.
// By default, it uses the JSON marshaller.
var Marshal = func(v interface{}) (io.Reader, error) {
	b, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		return nil, err
	}
	return bytes.NewReader(b), nil
}

// Save saves a representation of v to the file at path.
func Save(path string, v interface{}) error {
	lock.Lock()
	defer lock.Unlock()
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	r, err := Marshal(v)
	if err != nil {
		return err
	}
	_, err = io.Copy(f, r)
	return err
}

// Unmarshal is a function that unmarshals the data from the
// reader into the specified value.
// By default, it uses the JSON unmarshaller.
var Unmarshal = func(r io.Reader, v interface{}) error {
	return json.NewDecoder(r).Decode(v)
}

// Load loads the file at path into v.
// Use os.IsNotExist() to see if the returned error is due
// to the file being missing.
func Load(path string, v interface{}) error {
	lock.Lock()
	defer lock.Unlock()
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return Unmarshal(f, v)
}

// LogObject is used to create testfiles for golden testing
func LogObject(functionName string, objectName string, now time.Time, v interface{}) {
	timestamp := strconv.FormatInt(now.UTC().Unix(), 10)
	Save("/testfiles/temp/"+functionName+"_"+objectName+"_"+timestamp+".golden", v)
}

// UniqueInt returns a unique subset of the int slice provided.
func UniqueInt(input []int) []int { // Source: https://kylewbanks.com/blog/creating-unique-slices-in-go
	u := make([]int, 0, len(input))
	m := make(map[int]bool)

	for _, val := range input {
		if _, ok := m[val]; !ok {
			m[val] = true
			u = append(u, val)
		}
	}

	return u
}

// IsInSliceFloat64 takes a slice and looks for an element in it. If found it will
// return it's key, otherwise it will return -1 and a bool of false.
func IsInSliceFloat64(slice []float64, val float64) bool {
	for _, item := range slice {
		if item == val {
			return true
		}
	}
	return false
}

// IsInSliceInt32 takes a slice and looks for an element in it. If found it will
// return it's key, otherwise it will return -1 and a bool of false.
func IsInSliceInt32(slice []int32, val int32) bool {
	for _, item := range slice {
		if item == val {
			return true
		}
	}
	return false
}

// Divmod allows division with remainder. Source: https://stackoverflow.com/questions/43945675/division-with-returning-quotient-and-remainder
func Divmod(numerator, denominator int64) (quotient, remainder int64) {
	quotient = numerator / denominator // integer division, decimals are truncated
	remainder = numerator % denominator
	return
}
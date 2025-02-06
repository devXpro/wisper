package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

// generateRandomFilename creates a random filename while preserving the original extension
func generateRandomFilename(originalFilename string) (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	ext := filepath.Ext(originalFilename)
	return hex.EncodeToString(bytes) + ext, nil
}

func main() {
	r := gin.Default()
	r.POST("/transcribe", handleTranscription)

	fmt.Println("Server is running on :8080")
	r.Run(":8080")
}

func handleTranscription(c *gin.Context) {
	// Get model parameter from request, default to "turbo"
	model := c.DefaultPostForm("model", "turbo")

	file, err := c.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to read file"})
		return
	}

	// Create a temporary directory for this request
	tmpDir, err := os.MkdirTemp("", "whisper-*")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create temp directory"})
		return
	}
	// Clean up temporary directory and its contents after processing
	defer os.RemoveAll(tmpDir)

	// Generate random filename for input file
	randomFilename, err := generateRandomFilename(file.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate filename"})
		return
	}

	// Save input file to temporary directory
	inputPath := filepath.Join(tmpDir, randomFilename)
	if err := c.SaveUploadedFile(file, inputPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	// Run whisper command with auto language detection
	cmd := exec.Command(
		"whisper",
		inputPath,
		"--device", "cuda",
		"--model", model,
		"--output_dir", tmpDir,
		"--output_format", "txt",
	)

	// Capture command output for error logging
	output, err := cmd.CombinedOutput()
	if err != nil {
		c.JSON(
			http.StatusInternalServerError,
			gin.H{
				"error":   "Transcription failed",
				"details": string(output),
				"command": cmd.String(),
			},
		)
		return
	}

	// Read transcription result (whisper adds .txt extension to input filename)
	outputPath := inputPath + ".txt"
	result, err := os.ReadFile(outputPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to read transcription",
			"path":  outputPath,
		})
		return
	}

	// Return transcription text
	c.String(http.StatusOK, string(result))
}

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

type ServiceManager struct {
	app      *tview.Application
	list     *tview.List
	info     *tview.TextView
	services []string
}

func NewServiceManager() *ServiceManager {
	sm := &ServiceManager{
		app:  tview.NewApplication(),
		list: tview.NewList(),
		info: tview.NewTextView(),
	}

	// Set colors - Navy blue background and terminal yellow text
	sm.list.SetBackgroundColor(tcell.ColorBlack)
	sm.list.SetMainTextColor(tcell.ColorWhite)
	sm.list.SetSelectedTextColor(tcell.ColorWhite)
	sm.list.SetSelectedBackgroundColor(tcell.ColorGreen)

	sm.info.SetBackgroundColor(tcell.ColorBlack)
	sm.info.SetTextColor(tcell.ColorWhite)
	sm.info.SetBorder(true)
	sm.info.SetTitle(" Service Information ")
	sm.info.SetTitleColor(tcell.ColorWhite)
	sm.info.SetBorderColor(tcell.ColorWhite)

	sm.list.SetBorder(true)
	sm.list.SetTitle(" Service Manager (/etc/init.d/) ")
	sm.list.SetTitleColor(tcell.ColorWhite)
	sm.list.SetBorderColor(tcell.ColorWhite)

	return sm
}

func (sm *ServiceManager) loadServices() error {
	files, err := ioutil.ReadDir("/etc/init.d/")
	if err != nil {
		return fmt.Errorf("failed to read /etc/init.d/: %v", err)
	}

	sm.services = make([]string, 0)
	for _, file := range files {
		if !file.IsDir() && file.Mode()&0111 != 0 { // Check if executable
			sm.services = append(sm.services, file.Name())
		}
	}

	sort.Strings(sm.services)
	return nil
}

func (sm *ServiceManager) populateList() {
	sm.list.Clear()
	for i, service := range sm.services {
		sm.list.AddItem(service, "", rune('0'+i%10), func() {
			sm.handleServiceSelection()
		})
	}

	// Set up selection change handler
	sm.list.SetChangedFunc(func(index int, mainText, secondaryText string, shortcut rune) {
		if index >= 0 && index < len(sm.services) {
			sm.showServiceInfo(sm.services[index])
		}
	})
}

func (sm *ServiceManager) showServiceInfo(serviceName string) {
	servicePath := filepath.Join("/etc/init.d/", serviceName)
	
	// Get service status
	status := sm.getServiceStatus(serviceName)
	
	// Get file info
	fileInfo, err := os.Stat(servicePath)
	var sizeStr, modeStr string
	if err == nil {
		sizeStr = fmt.Sprintf("%d bytes", fileInfo.Size())
		modeStr = fileInfo.Mode().String()
	} else {
		sizeStr = "Unknown"
		modeStr = "Unknown"
	}

	infoText := fmt.Sprintf(`[yellow]Service: [white]%s

[yellow]Status: [white]%s
[yellow]Path: [white]%s
[yellow]Size: [white]%s
[yellow]Permissions: [white]%s

[yellow]Commands:
[white]• Press [yellow]Enter[white] to see available actions
[white]• Press [yellow]s[white] to start service
[white]• Press [yellow]t[white] to stop service
[white]• Press [yellow]r[white] to restart service
[white]• Press [yellow]c[white] to check status
[white]• Press [yellow]q[white] to quit

[yellow]Note:[white] Operations require sudo privileges`,
		serviceName, status, servicePath, sizeStr, modeStr)

	sm.info.SetText(infoText)
}

func (sm *ServiceManager) getServiceStatus(serviceName string) string {
	cmd := exec.Command("sudo", "service", serviceName, "status")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "Unknown/Error"
	}
	
	outputStr := strings.ToLower(string(output))
	if strings.Contains(outputStr, "running") || strings.Contains(outputStr, "active") {
		return "Running"
	} else if strings.Contains(outputStr, "stopped") || strings.Contains(outputStr, "inactive") {
		return "Stopped"
	}
	return "Unknown"
}

func (sm *ServiceManager) handleServiceSelection() {
	currentIndex := sm.list.GetCurrentItem()
	if currentIndex < 0 || currentIndex >= len(sm.services) {
		return
	}

	serviceName := sm.services[currentIndex]
	
	modal := tview.NewModal().
		SetText(fmt.Sprintf("Select action for service: %s", serviceName)).
		AddButtons([]string{"Start", "Stop", "Restart", "Status", "Cancel"}).
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			sm.app.SetRoot(sm.createLayout(), true)
			
			switch buttonLabel {
			case "Start":
				sm.executeServiceCommand(serviceName, "start")
			case "Stop":
				sm.executeServiceCommand(serviceName, "stop")
			case "Restart":
				sm.executeServiceCommand(serviceName, "restart")
			case "Status":
				sm.executeServiceCommand(serviceName, "status")
			}
		})

	modal.SetBackgroundColor(tcell.ColorBlack)
	modal.SetTextColor(tcell.ColorWhite)
	modal.SetButtonBackgroundColor(tcell.ColorBlack)
	modal.SetButtonTextColor(tcell.ColorWhite)
	modal.SetBorderColor(tcell.ColorWhite)

	sm.app.SetRoot(modal, true)
}

func (sm *ServiceManager) executeServiceCommand(serviceName, action string) {
	cmd := exec.Command("sudo", "service", serviceName, action)
	output, err := cmd.CombinedOutput()
	
	var resultText string
	if err != nil {
		resultText = fmt.Sprintf("Error executing '%s %s':\n%s\n%v", serviceName, action, string(output), err)
	} else {
		resultText = fmt.Sprintf("Command '%s %s' executed successfully:\n%s", serviceName, action, string(output))
	}

	modal := tview.NewModal().
		SetText(resultText).
		AddButtons([]string{"OK"}).
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			sm.app.SetRoot(sm.createLayout(), true)
			// Refresh the service info
			sm.showServiceInfo(serviceName)
		})

	modal.SetBackgroundColor(tcell.ColorBlack)
	modal.SetTextColor(tcell.ColorWhite)
	modal.SetButtonBackgroundColor(tcell.ColorBlack)
	modal.SetButtonTextColor(tcell.ColorWhite)
	modal.SetBorderColor(tcell.ColorWhite)

	sm.app.SetRoot(modal, true)
}

func (sm *ServiceManager) createLayout() *tview.Flex {
	// Create main layout
	flex := tview.NewFlex().
		AddItem(sm.list, 0, 1, true).
		AddItem(sm.info, 0, 1, false)

	flex.SetBackgroundColor(tcell.ColorBlack)

	return flex
}

func (sm *ServiceManager) setupKeyBindings() {
	sm.app.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		switch event.Rune() {
		case 'q', 'Q':
			sm.app.Stop()
			return nil
		case 's', 'S':
			currentIndex := sm.list.GetCurrentItem()
			if currentIndex >= 0 && currentIndex < len(sm.services) {
				sm.executeServiceCommand(sm.services[currentIndex], "start")
			}
			return nil
		case 't', 'T':
			currentIndex := sm.list.GetCurrentItem()
			if currentIndex >= 0 && currentIndex < len(sm.services) {
				sm.executeServiceCommand(sm.services[currentIndex], "stop")
			}
			return nil
		case 'r', 'R':
			currentIndex := sm.list.GetCurrentItem()
			if currentIndex >= 0 && currentIndex < len(sm.services) {
				sm.executeServiceCommand(sm.services[currentIndex], "restart")
			}
			return nil
		case 'c', 'C':
			currentIndex := sm.list.GetCurrentItem()
			if currentIndex >= 0 && currentIndex < len(sm.services) {
				sm.executeServiceCommand(sm.services[currentIndex], "status")
			}
			return nil
		}
		return event
	})
}

func (sm *ServiceManager) Run() error {
	// Load services
	if err := sm.loadServices(); err != nil {
		return err
	}

	// Populate the list
	sm.populateList()

	// Show info for first service if available
	if len(sm.services) > 0 {
		sm.showServiceInfo(sm.services[0])
	}

	// Setup key bindings
	sm.setupKeyBindings()

	// Create and set root layout
	root := sm.createLayout()
	sm.app.SetRoot(root, true)

	// Run the application
	return sm.app.Run()
}

func main() {
	// Check if running as root or with sudo
	if os.Geteuid() != 0 {
		fmt.Println("Warning: This application requires sudo privileges to manage services.")
		fmt.Println("Some operations may fail without proper permissions.")
		fmt.Println("Consider running with: sudo go run main.go")
		fmt.Println()
	}

	sm := NewServiceManager()
	if err := sm.Run(); err != nil {
		log.Fatalf("Error running service manager: %v", err)
	}
}

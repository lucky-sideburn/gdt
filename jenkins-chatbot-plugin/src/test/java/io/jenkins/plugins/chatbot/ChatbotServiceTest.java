package io.jenkins.plugins.chatbot;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for ChatbotService
 */
public class ChatbotServiceTest {
    
    private ChatbotService chatbotService = new ChatbotService();
    
    @Test
    public void testHelpResponse() {
        ChatbotResponse response = chatbotService.processMessage("help", "test-student");
        assertEquals("help", response.getMessageType());
        assertTrue(response.getMessage().contains("Jenkins build assistant"));
    }
    
    @Test
    public void testGreetingResponse() {
        ChatbotResponse response = chatbotService.processMessage("hello", "test-student");
        assertEquals("greeting", response.getMessageType());
        assertTrue(response.getMessage().contains("Hello"));
    }
    
    @Test
    public void testBuildNumberExtraction() {
        ChatbotResponse response = chatbotService.processMessage("build 5", "test-student");
        // Should handle build request (even if no job exists, it should recognize the pattern)
        assertTrue(response.getMessageType().equals("build_not_found") || response.getMessageType().equals("build_started"));
    }
    
    @Test
    public void testListBuildsRequest() {
        ChatbotResponse response = chatbotService.processMessage("list builds", "test-student");
        assertEquals("build_list", response.getMessageType());
    }
    
    @Test
    public void testDefaultResponse() {
        ChatbotResponse response = chatbotService.processMessage("random text", "test-student");
        assertEquals("default", response.getMessageType());
        assertTrue(response.getMessage().contains("not sure"));
    }
}

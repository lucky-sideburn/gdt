package io.jenkins.plugins.chatbot;

/**
 * Response object for chatbot interactions
 */
public class ChatbotResponse {
    private final String message;
    private final String messageType;
    private final Object data;
    
    public ChatbotResponse(String message, String messageType, Object data) {
        this.message = message;
        this.messageType = messageType;
        this.data = data;
    }
    
    public String getMessage() {
        return message;
    }
    
    public String getMessageType() {
        return messageType;
    }
    
    public Object getData() {
        return data;
    }
}

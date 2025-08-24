package io.jenkins.plugins.chatbot;

import hudson.Extension;
import hudson.model.RootAction;
import jenkins.model.Jenkins;
import org.kohsuke.stapler.HttpResponse;
import org.kohsuke.stapler.HttpResponses;
import org.kohsuke.stapler.QueryParameter;
import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;
import org.kohsuke.stapler.verb.POST;

import javax.servlet.ServletException;
import java.io.IOException;
import java.util.logging.Logger;

/**
 * Main entry point for the Student Chatbot plugin.
 * Provides a web interface for students to interact with the chatbot.
 */
@Extension
public class ChatbotRootAction implements RootAction {
    
    private static final Logger LOGGER = Logger.getLogger(ChatbotRootAction.class.getName());
    private final ChatbotService chatbotService;
    
    public ChatbotRootAction() {
        this.chatbotService = new ChatbotService();
    }
    
    @Override
    public String getIconFileName() {
        return "symbol-chat-outline plugin-ionicons-api";
    }
    
    @Override
    public String getDisplayName() {
        return "Student Chatbot";
    }
    
    @Override
    public String getUrlName() {
        return "student-chatbot";
    }
    
    /**
     * Main chatbot page
     */
    public void doIndex(StaplerRequest req, StaplerResponse rsp) throws ServletException, IOException {
        Jenkins.get().checkPermission(Jenkins.READ);
        req.getView(this, "index.jelly").forward(req, rsp);
    }
    
    /**
     * Handle chatbot messages via AJAX
     */
    @POST
    public HttpResponse doChat(@QueryParameter("message") String message,
                              @QueryParameter("studentId") String studentId) {
        Jenkins.get().checkPermission(Jenkins.READ);
        
        if (message == null || message.trim().isEmpty()) {
            return HttpResponses.errorJSON("Message cannot be empty");
        }
        
        try {
            ChatbotResponse response = chatbotService.processMessage(message, studentId);
            return HttpResponses.okJSON(response);
        } catch (Exception e) {
            LOGGER.severe("Error processing chatbot message: " + e.getMessage());
            return HttpResponses.errorJSON("Sorry, I encountered an error. Please try again.");
        }
    }
    
    /**
     * Get available builds for a student
     */
    public HttpResponse doGetBuilds(@QueryParameter("studentId") String studentId) {
        Jenkins.get().checkPermission(Jenkins.READ);
        
        try {
            return HttpResponses.okJSON(chatbotService.getAvailableBuilds(studentId));
        } catch (Exception e) {
            LOGGER.severe("Error getting builds for student: " + e.getMessage());
            return HttpResponses.errorJSON("Error retrieving builds");
        }
    }
    
    /**
     * Start a specific build for a student
     */
    @POST
    public HttpResponse doStartBuild(@QueryParameter("buildNumber") String buildNumber,
                                   @QueryParameter("studentId") String studentId) {
        Jenkins.get().checkPermission(Jenkins.BUILD);
        
        try {
            boolean success = chatbotService.startBuild(buildNumber, studentId);
            if (success) {
                return HttpResponses.okJSON("Build started successfully!");
            } else {
                return HttpResponses.errorJSON("Failed to start build");
            }
        } catch (Exception e) {
            LOGGER.severe("Error starting build: " + e.getMessage());
            return HttpResponses.errorJSON("Error starting build: " + e.getMessage());
        }
    }
}

package io.jenkins.plugins.chatbot;

import hudson.model.Job;
import hudson.model.ParametersAction;
import hudson.model.ParametersDefinitionProperty;
import hudson.model.StringParameterValue;
import hudson.model.queue.QueueTaskFuture;
import jenkins.model.Jenkins;
import hudson.model.FreeStyleProject;

import java.util.*;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service class that handles chatbot logic and interactions with Jenkins jobs.
 */
public class ChatbotService {
    
    private static final Logger LOGGER = Logger.getLogger(ChatbotService.class.getName());
    
    // Pattern to match numbered build requests
    private static final Pattern BUILD_NUMBER_PATTERN = Pattern.compile("(?:build|start|run)\\s*(\\d+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern HELP_PATTERN = Pattern.compile("(?:help|\\?|what|how)", Pattern.CASE_INSENSITIVE);
    private static final Pattern LIST_PATTERN = Pattern.compile("(?:list|show|available|builds)", Pattern.CASE_INSENSITIVE);
    
    /**
     * Process incoming chatbot message and return appropriate response
     */
    public ChatbotResponse processMessage(String message, String studentId) {
        LOGGER.info("Processing message from student " + studentId + ": " + message);
        
        String cleanMessage = message.trim().toLowerCase();
        
        // Handle help requests
        if (HELP_PATTERN.matcher(cleanMessage).find()) {
            return createHelpResponse();
        }
        
        // Handle list requests
        if (LIST_PATTERN.matcher(cleanMessage).find()) {
            return createListBuildsResponse(studentId);
        }
        
        // Handle build number requests
        Matcher buildMatcher = BUILD_NUMBER_PATTERN.matcher(cleanMessage);
        if (buildMatcher.find()) {
            String buildNumber = buildMatcher.group(1);
            return handleBuildRequest(buildNumber, studentId);
        }
        
        // Handle greetings
        if (cleanMessage.matches("(?:hi|hello|hey|good morning|good afternoon).*")) {
            return createGreetingResponse(studentId);
        }
        
        // Default response for unrecognized input
        return createDefaultResponse();
    }
    
    /**
     * Get list of available builds for a student
     */
    public List<BuildInfo> getAvailableBuilds(String studentId) {
        List<BuildInfo> builds = new ArrayList<>();
        
        // Get all jobs that match the student build pattern
        Jenkins jenkins = Jenkins.get();
        Collection<Job> jobs = jenkins.getAllItems(Job.class);
        
        for (Job job : jobs) {
            // Look for jobs with naming pattern like "student-build-01", "student-build-02", etc.
            String jobName = job.getName();
            if (jobName.matches("student-build-\\d+") || jobName.matches("build-\\d+")) {
                String buildNumber = extractBuildNumber(jobName);
                builds.add(new BuildInfo(buildNumber, jobName, job.getDescription()));
            }
        }
        
        // Sort by build number
        builds.sort(Comparator.comparing(BuildInfo::getBuildNumber));
        
        return builds;
    }
    
    /**
     * Start a specific build for a student
     */
    public boolean startBuild(String buildNumber, String studentId) {
        try {
            String jobName = findJobNameByBuildNumber(buildNumber);
            if (jobName == null) {
                LOGGER.warning("No job found for build number: " + buildNumber);
                return false;
            }
            
            Jenkins jenkins = Jenkins.get();
            Job job = jenkins.getItemByFullName(jobName, Job.class);
            
            if (job == null) {
                LOGGER.warning("Job not found: " + jobName);
                return false;
            }
            
            // Check if job has parameters and add student ID
            ParametersAction parametersAction = null;
            ParametersDefinitionProperty paramDef = job.getProperty(ParametersDefinitionProperty.class);
            if (paramDef != null) {
                List<StringParameterValue> parameters = new ArrayList<>();
                parameters.add(new StringParameterValue("STUDENT_ID", studentId));
                parameters.add(new StringParameterValue("BUILD_NUMBER", buildNumber));
                parametersAction = new ParametersAction(parameters);
            }
            
            // Schedule the build
            QueueTaskFuture<?> future;
            if (parametersAction != null) {
                future = job.scheduleBuild2(0, parametersAction);
            } else {
                future = job.scheduleBuild2(0);
            }
            
            LOGGER.info("Build scheduled for student " + studentId + ": " + jobName);
            return future != null;
            
        } catch (Exception e) {
            LOGGER.severe("Error starting build: " + e.getMessage());
            return false;
        }
    }
    
    private ChatbotResponse createHelpResponse() {
        StringBuilder help = new StringBuilder();
        help.append("👋 Hi! I'm your Jenkins build assistant. Here's what I can help you with:\n\n");
        help.append("• **list** or **show builds** - See available builds\n");
        help.append("• **build 1** or **start 1** - Start build number 1\n");
        help.append("• **build 2** or **run 2** - Start build number 2\n");
        help.append("• **help** - Show this help message\n\n");
        help.append("Just type a build number (like '1', '2', '3') to start that build!");
        
        return new ChatbotResponse(help.toString(), "help", null);
    }
    
    private ChatbotResponse createListBuildsResponse(String studentId) {
        List<BuildInfo> builds = getAvailableBuilds(studentId);
        
        if (builds.isEmpty()) {
            return new ChatbotResponse(
                "No builds are currently available. Please contact your instructor.",
                "no_builds",
                null
            );
        }
        
        StringBuilder response = new StringBuilder();
        response.append("📋 **Available Builds:**\n\n");
        
        for (BuildInfo build : builds) {
            response.append("**Build ").append(build.getBuildNumber()).append("** - ");
            response.append(build.getJobName());
            if (build.getDescription() != null && !build.getDescription().isEmpty()) {
                response.append("\n   ").append(build.getDescription());
            }
            response.append("\n\n");
        }
        
        response.append("Type **build X** (where X is the number) to start a build!");
        
        return new ChatbotResponse(response.toString(), "build_list", builds);
    }
    
    private ChatbotResponse handleBuildRequest(String buildNumber, String studentId) {
        // Check if build exists
        String jobName = findJobNameByBuildNumber(buildNumber);
        if (jobName == null) {
            return new ChatbotResponse(
                "❌ Build " + buildNumber + " not found. Type **list** to see available builds.",
                "build_not_found",
                null
            );
        }
        
        // Attempt to start the build
        boolean success = startBuild(buildNumber, studentId);
        if (success) {
            return new ChatbotResponse(
                "🚀 **Build " + buildNumber + " started!**\n\n" +
                "Your build has been queued and will start shortly. " +
                "You can monitor its progress in the Jenkins dashboard.",
                "build_started",
                new BuildInfo(buildNumber, jobName, "Build started successfully")
            );
        } else {
            return new ChatbotResponse(
                "❌ Failed to start build " + buildNumber + ". Please try again or contact your instructor.",
                "build_failed",
                null
            );
        }
    }
    
    private ChatbotResponse createGreetingResponse(String studentId) {
        return new ChatbotResponse(
            "👋 Hello! I'm here to help you start your Jenkins builds.\n\n" +
            "Type **list** to see available builds, or **help** for more options.",
            "greeting",
            null
        );
    }
    
    private ChatbotResponse createDefaultResponse() {
        return new ChatbotResponse(
            "🤔 I'm not sure what you mean. Try:\n" +
            "• **list** - to see available builds\n" +
            "• **build X** - to start build number X\n" +
            "• **help** - for more options",
            "default",
            null
        );
    }
    
    private String extractBuildNumber(String jobName) {
        Pattern pattern = Pattern.compile(".*-(\\d+)$");
        Matcher matcher = pattern.matcher(jobName);
        return matcher.find() ? matcher.group(1) : "0";
    }
    
    private String findJobNameByBuildNumber(String buildNumber) {
        Jenkins jenkins = Jenkins.get();
        Collection<Job> jobs = jenkins.getAllItems(Job.class);
        
        for (Job job : jobs) {
            String jobName = job.getName();
            if (jobName.equals("student-build-" + String.format("%02d", Integer.parseInt(buildNumber))) ||
                jobName.equals("build-" + buildNumber) ||
                jobName.equals("student-build-" + buildNumber)) {
                return jobName;
            }
        }
        return null;
    }
}

import yaml
import requests
import os
import urllib3
import urllib.parse
import glob

from difflib import SequenceMatcher
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)



# Delete all issues from Redmine
def delete_all_issues():
  issues_url = f"{redmine_url}/issues.json"
  headers = {
    'Content-Type': 'application/json',
    'X-Redmine-API-Key': api_key,
  }

  # Fetch all issues
  response = requests.get(issues_url, headers=headers, verify=False)
  if response.status_code == 200:
    issues = []
    while response.status_code == 200:
      data = response.json()
      issues.extend(data.get('issues', []))
      next_offset = data.get('offset', 0) + data.get('limit', 100)
      if next_offset >= data.get('total_count', 0):
        break
      response = requests.get(f"{issues_url}?offset={next_offset}", headers=headers, verify=False)
    print(f"Total issues fetched: {len(issues)}")
    for issue in issues:
      issue_id = issue['id']
      delete_url = f"{redmine_url}/issues/{issue_id}.json"
      delete_response = requests.delete(delete_url, headers=headers, verify=False)
      if delete_response.status_code == 200 or delete_response.status_code == 204:
        print(f"Issue with ID {issue_id} deleted successfully.")
      else:
        print(f"Failed to delete issue with ID {issue_id}. Status code: {delete_response.status_code}, Response: {delete_response.text}")
  else:
    print(f"Failed to fetch issues. Status code: {response.status_code}, Response: {response.text}")


# Add the student as a member to the project with limited permissions
def add_member_to_project(project_name, user_login):
  membership_url = f"{redmine_url}/projects/{project_name}/memberships.json"
  headers = {
    'Content-Type': 'application/json',
    'X-Redmine-API-Key': api_key,
  }
  payload = {
    'membership': {
      'user': {
        'login': user_login
      },
      'role_ids': [3]  # Assuming role ID 3 corresponds to a limited permission role
    }
  }
  response = requests.post(membership_url, json=payload, headers=headers, verify=False)

  if response.status_code == 201:
    print(f"User '{user_login}' added to project '{project_name}' with limited permissions.")
  else:
    print(f"Failed to add user '{user_login}' to project '{project_name}'. Status code: {response.status_code}, Response: {response.text}")

# Create a new project on Redmine
def create_redmine_project(project_name, student_name):
  url = f"{redmine_url}/projects.json"
  headers = {
    'Content-Type': 'application/json',
    'X-Redmine-API-Key': api_key,
  }
  payload = {
    'project': {
      'name': project_name,
      'identifier': project_name.lower().replace(' ', '_'),
      'description': f"Project for {project_name}",
      'is_public': False
    }
  }

  # Create the project
  response = requests.post(url, json=payload, headers=headers, verify=False)

  if response.status_code == 201:
    print(f"Project '{project_name}' created successfully.")
  else:
    print(f"Failed to create project '{project_name}'. Status code: {response.status_code}, Response: {response.text}")


  # Create a user for the project
  user_url = f"{redmine_url}/users.json"
  user_payload = {
    'user': {
      'login': student_name.lower().replace(' ', '_'),
      'firstname': student_name,
      'lastname': 'User',
      'mail': f"{student_name.lower().replace(' ', '_')}@example.com",
      'password': os.urandom(8).hex()  # Generate a random password
    }
  }
  user_response = requests.post(user_url, json=user_payload, headers=headers, verify=False)

  if user_response.status_code == 201:
    print(f"User for '{project_name}' created successfully.")
  else:
    print(f"Failed to create user for '{project_name}'. Status code: {user_response.status_code}, Response: {user_response.text}")
  response = requests.post(url, json=payload, headers=headers, verify=False)

  if response.status_code == 201:
    print(f"Project '{project_name}' created successfully.")
  else:
    print(f"Failed to create project '{project_name}'. Status code: {response.status_code}, Response: {response.text}")

# Path to the main.yml file
main_yml_path = '/home/ubuntu/jenkins-lfs/playbooks/roles/ansible-gdt/vars/main.yml'

# Redmine API configuration
redmine_url = 'https://academy.garantideltalento.it'
api_key = os.getenv('REDMINE_API_KEY')
student_name = "student1"
project_name = f"Formazione - {student_name}"

create_redmine_project(project_name, student_name)
add_member_to_project(project_name, student_name)
delete_all_issues()

# Read and parse the YAML file
with open(main_yml_path, 'r') as file:
  data = yaml.safe_load(file)
# Loop over all items in the YAML file
for folder in data['jenkins_jobs']['folders']:
  print(f"Processing folder: {folder}")
  cnt = 1
  for job in data['jenkins_jobs'][folder]:
    
    # Find all files in the specified folder
    workspace_folder = f"/var/lib/jenkins/workspace/{folder}"
    files = glob.glob(f"{workspace_folder}/**/*", recursive=True)
    jenkins_job_url = ""
    print(f"Found {len(files)} files in folder: {workspace_folder}")
    for file_path in files:
      print(f"File: {file_path}")
      jobname = os.path.basename(file_path)
      print(f"JobName: {jobname}")
      print(f"JobName: {job['name']}")
      if jobname == job['name']:
        jenkins_job_url = urllib.parse.quote("https://jenkins.garantideltalento.it/job/" + folder + "/job/" + jobname, safe=':/')
 
    if jenkins_job_url == "":
      print(f"Warning: No Jenkins job URL found for job '{job['name']}' in folder '{folder}'. Skipping issue creation.")
      exit(0)

    print(f"Processing job: {job['name']}")
    print(f"Voce Area Description: {job.get('description', 'No description')}")
    print(f"Voice Job Category: {job.get('category', 'No category')}")
    print(f"Jenkins Job URL: {jenkins_job_url}")
    # Create an issue for the job in Redmine
    issue_url = f"{redmine_url}/issues.json"
    headers = {
      'Content-Type': 'application/json',
      'X-Redmine-API-Key': api_key,
    }
    issue_payload = {
      'issue': {
      'project_id': project_name.lower().replace(' ', '_'),
      'subject': f"[{cnt}] - " + job['name'],
      'description': f"Area Description: {job.get('description', 'No description')}\n"
           f"Job Category: {job.get('category', 'No category')}\n"
           f"Linux From Scratch Section: {folder}\n"
           f"Jenkins Job URL: {jenkins_job_url}",
      'tracker_id': 5,  # Assuming tracker ID 1 corresponds to a default tracker
      'priority_id': 1  # Assuming priority ID 4 corresponds to a normal priority
      }
    }
    cnt += 1
    issue_response = requests.post(issue_url, json=issue_payload, headers=headers, verify=False)

    if issue_response.status_code == 201:
      print(f"Issue for job '{job['name']}' created successfully.")
    else:
      print(f"Failed to create issue for job '{job['name']}'. Status code: {issue_response.status_code}, Response: {issue_response.text}")

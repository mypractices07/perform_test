
////////////////////////////////////////

MattermostChannel = 'comet-pipeline'
MattermostEndpoint = 'https://mattermost.hyland.com/hooks/9h1snfozftfotxj3t8nt6ybyra'
// MongoDBAgentLabel = 'cua-capture-mongodb-linux'
WindowsAgentLabel = 'cua-performance-Windows'
// ApiGatewayAgentLabel = 'cua-capture-api-gateway-linux'
// BatchManagementAgentLabel = 'cua-capture-batch-management-linux'
// WebappAgentLabel = 'cua-web-app-performance'
// RabitAgentLabel = 'cua-capture-rabbit-linux'
// GraphQLAgentLabel = 'cua-graphql-vm-linux'
// OrchestrationAgentLabel = 'cua-orchestration-linux'
// StorageAgentLabel = 'cua-storage-vm-linux'
// OcrAgentlabel = 'cua-ocr-windows'
// AleAgentlabel = 'cua-ale-windows'
//ApiGatewayWindowsAgentLabel = 'cua-capture-api-gateway-windows'

// these are possible values for `currentBuild.result`
SUCCESS = 'SUCCESS'
UNSTABLE = 'UNSTABLE'
FAILURE = 'FAILURE'
ABORTED = 'ABORTED'
NOT_BUILT = 'NOT_BUILT'

// Mattermost colors
MATTERMOST_RED = 'danger'
MATTERMOST_YELLOW = 'warning'
MATTERMOST_GREEN = 'good'

// Mattermost conditions
SEND_FOR_MASTER_ONLY = true
SEND_FOR_ALL_BRANCHES = false

// Global State
////////////////////////////////////////

State = [
  haveReport: false, // set to true only after a performance report has been created for the current build
  notified: false,
  commits: [
    webapp: null,  // commit sha1 for CCOM/capture-verifier
    graphql: null, // commit sha1 for CCOM/ms_verifier_backendapi
  ],
]



// sends a uniformly-decorated mattermost message
// onlyOnMaster: SEND_FOR_MASTER_ONLY (true) | SEND_FOR_ALL_BRANCHES (false)
// colors: MATTERMOST_GREEN ('good') | MATTERMOST_YELLOW ('warning') | MATTERMOST_RED ('danger')
// message: arbitrary markdown; will be preceded by a header and succeeded by a footer
void MessageMattermost(Boolean onlyOnMaster, String color, String message) {
  // conditionally refuse to send the message (so as not to spam the team)
  if (State.notified) { return; }
  State.notified = true
  if (onlyOnMaster && env.GIT_BRANCH != 'master') {
    echo "Not sending mattermost message for non-master branch: $message"
    return
  }
  echo "Sending message to Mattermost channel \"$MattermostChannel\": $message"

  // conditional links
  def b1 = State.commits.webapp ? '[capture-verifier]' : '~~capture-verifier~~'
  def b2 = State.commits.graphql ? '[ms_verifier_backendapi]' : '~~ms_verifier_backendapi~~'
  def j3 = State.haveReport ? '[Performance Report]' : '~~Performance Report~~'

  def footer = """
    Bitbucket: $b1 | $b2
    Jenkins CI: [Classic] | [Blue Ocean] | $j3

    [Classic]: $BUILD_URL
    [Blue Ocean]: $RUN_DISPLAY_URL
    [Performance Report]: ${BUILD_URL}performance
    [capture-verifier]: https://bitbucket.hylandqa.net/projects/CUA/repos/capture-verifier/commits/$State.commits.webapp
    [ms_verifier_backendapi]: https://bitbucket.hylandqa.net/projects/CUA/repos/ms_verifier_backendapi/commits/$State.commits.graphql
  """.stripIndent().trim()

  mattermostSend \
  text: "__Capture Verifier Performance Pipeline:__ Build *$BUILD_DISPLAY_NAME* of *$BRANCH_NAME*",
  message: "$message\n$footer",
  color: color,
  failOnError: true,
  channel: MattermostChannel,
  endpoint: MattermostEndpoint
}

// Pipeline
////////////////////////////////////////

// TODO: Move all appropriate/applicable work to Cake
pipeline {
  agent none // this is to ensure the timeout option applies regardless of agent availability
  options {
    timestamps()
    lock('CCOM/hxc-verifier-perf') // we only have one set of dedicated VMs!
    checkoutToSubdirectory 'src'
    timeout time: 10, unit: 'HOURS'
  }
  triggers {
    // Run master at 12:00 UTC on Everyday
    // See https://jenkins.io/doc/book/pipeline/syntax/#cron-syntax and/or https://crontab.guru/ <-- FAR MORE HELPFUL!!
    cron(BRANCH_NAME in ['master' ,'develop']  ? '00 12 * * 1-7' : '')    
  }
  parameters {
      choice name: 'Environment', choices: [ 'AWS sandbox','AWS dev', 'AWS staging'],
      description: 'Environment to use. If you choose one of the AWS options, please leave the other parameters as their default values (DebugE2E still available)'
  }
  environment {
 
    CORS_ORIGIN = '*'

 
  }

  stages {

    stage('Initialize Global Variables') {
      agent {
        kubernetes {
          label "hxc-perf-${UUID.randomUUID().toString()}"
          yamlFile './build-spec.yml'
          defaultContainer 'ngweb-node'
        }
      }
      steps {
        script {
		  CLIENT_ID='test-client'
	      CLIENT_SECRET='secret-123'
           if (params.Environment == 'AWS dev') {
             HXC_URL = 'https://faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d.hxc.dev.hxp.hyland.com'
             IDP_URL = 'https://auth.iam.dev.hxp.hyland.com/idp'
             PLATFORM_API = 'https://platform.hxc.dev.hxp.hyland.com'
            // VERIFIER_USERS = "{\"dataCreationUser\":{\"username\":\"bob\",\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"scope\":\"hxp\",\"tenantKey\":\"faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d\"},\"user0\":{\"fullname\":\"Avis Amey\",\"useremail\":\"aamey@email.com\",\"password\":\"wstinol2019\"},\"user1\":{\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"tenantKey\":\"students-a5c54760-4243-4b44-91ea-1ccb31637d5b\"},\"user2\":{\"fullname\":\"Bob Smith\",\"useremail\":\"bob.smith@email.com\",\"password\":\"badpassword\"}}"
            // CONFIGURL = "https://__tenant__.hxc-config.dev.hxp.hyland.com"
            VERIFIER_USERS = "{\"dataCreationUser\":{\"username\":\"bob\",\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"scope\":\"hxp\",\"tenantKey\":\"faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d\"},\"user0\":{\"fullname\":\"Avis Amey\",\"useremail\":\"aamey@email.com\",\"password\":\"wstinol2019\"},\"user1\":{\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"tenantKey\":\"students-a5c54760-4243-4b44-91ea-1ccb31637d5b\"},\"user2\":{\"fullname\":\"Bob Smith\",\"useremail\":\"bob.smith@email.com\",\"password\":\"badpassword\"}}"
            CONFIGURL = "https://__tenant__.hxc-config.dev.hxp.hyland.com"
          } else if (params.Environment == 'AWS staging') {
            HXC_URL = 'https://faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d.hxc.staging.hxp.hyland.com'
             IDP_URL = 'https://auth.iam.staging.hxp.hyland.com/idp'
             PLATFORM_API = 'https://platform.hxc.staging.hxp.hyland.com'
             VERIFIER_USERS = "{\"dataCreationUser\":{\"username\":\"bob\",\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"scope\":\"hxp\",\"tenantKey\":\"faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d\"},\"user0\":{\"fullname\":\"Avis Amey\",\"useremail\":\"aamey@email.com\",\"password\":\"wstinol2019\"},\"user1\":{\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"tenantKey\":\"students-a5c54760-4243-4b44-91ea-1ccb31637d5b\"},\"user2\":{\"fullname\":\"Bob Smith\",\"useremail\":\"bob.smith@email.com\",\"password\":\"badpassword\"}}"
             CONFIGURL = "https://__tenant__.hxc-config.staging.hxp.hyland.com"
          } else if (params.Environment == 'AWS sandbox') {
            HXC_URL = 'https://faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d.hxc.sandbox.hxp.hyland.com'
             IDP_URL = 'https://auth.iam.dev.hxp.hyland.com/idp'
             PLATFORM_API = 'https://platform.hxc.sandbox.hxp.hyland.com'
            // VERIFIER_USERS = "{\"dataCreationUser\":{\"username\":\"bob\",\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"scope\":\"hxp\",\"tenantKey\":\"faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d\"},\"user0\":{\"fullname\":\"Avis Amey\",\"useremail\":\"aamey@email.com\",\"password\":\"wstinol2019\"},\"user1\":{\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"tenantKey\":\"students-a5c54760-4243-4b44-91ea-1ccb31637d5b\"},\"user2\":{\"fullname\":\"Bob Smith\",\"useremail\":\"bob.smith@email.com\",\"password\":\"badpassword\"}}"
            // CONFIGURL = "https://__tenant__.hxc-config.dev.hxp.hyland.com"
            VERIFIER_USERS = "{\"dataCreationUser\":{\"username\":\"bob\",\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"scope\":\"hxp\",\"tenantKey\":\"faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d\"},\"user0\":{\"fullname\":\"Avis Amey\",\"useremail\":\"aamey@email.com\",\"password\":\"wstinol2019\"},\"user1\":{\"fullname\":\"Bob Smith\",\"useremail\":\"Bob.Smith@email.com\",\"password\":\"wstinol2019\",\"tenantKey\":\"students-a5c54760-4243-4b44-91ea-1ccb31637d5b\"},\"user2\":{\"fullname\":\"Bob Smith\",\"useremail\":\"bob.smith@email.com\",\"password\":\"badpassword\"}}"
            CONFIGURL = "https://__tenant__.hxc-config.dev.hxp.hyland.com"
          }
          IDP_EMAIL = 'bob.smith@email.com'
        }
      }
    }
    stage('Confirm agent availability') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          node(label: WindowsAgentLabel) {
            echo 'Available!'
          }
        }
      }
      post {
        aborted {
          MessageMattermost(SEND_FOR_ALL_BRANCHES, MATTERMOST_RED, '@all The performance pipeline **did not run** because the Windows Desktop VM was unavailable.')
          error 'Timed-out (or was manually aborted) while waiting for Windows agent to become available!'
        }
      }
    }
    stage('Prepare, Bench, and Publish') {
      agent {
        label WindowsAgentLabel
      }
      environment {
        Webdrivers = "C:\\Users\\cua\\AppData\\Roaming\\npm\\node_modules\\webdriver-manager\\selenium" // NOTE: this path MUST be absolute
      }
      stages {
        stage('Prepare Dependencies') {
          parallel {
            ////////////////////////////////////////
            // the next two stages download and prepare necessary software on the Windows Desktop VM
            stage('A. Chrome Webdriver') {
              steps {
                powershell 'src/Jenkins/Install-ChromeWebdriver.ps1 -Destination $env:Webdrivers -ErrorAction Stop; exit $LASTEXITCODE'
              }
            }
          }
        }
        stage('Bench') {
          failFast true
          parallel {
            // NOTE: The following stages' names have been given prefixes so as to control the order in which they are listed by Jenkins Blue Ocean.

            stage('A. JMeter') {
              environment {
                IDP_BASE = "${IDP_URL}"
                JMETER_HOME = 'C:\\opt\\apache-jmeter-5.3' // JMeter must ALREADY be installed--with the appropriate plugins--at this location on the Windows VM
                PLATFORM_API = "${PLATFORM_API}"
              }
              steps {
                powershell label: 'Create Setup and copy dependencies', script: '''
                   pushd .\\src\\
                   ./gradlew BuildAndCopyLibs
                   ./gradlew CopyDependencies
                   popd
                  '''
                powershell label: 'Clean workspace', script: 'Get-ChildItem -File | Remove-Item -Force -Verbose' // just in case jmeter artifacts are leftover from a previous run (shouldn't happen)

               // now for the actual testing...
                //withCredentials([usernamePassword(credentialsId: '171941e1-d525-4daa-990e-e0d947dc60d4', usernameVariable: 'IDP_USER', passwordVariable: 'IDP_PASSWD')]) {
                  // NOTE: credential changes should be performed by updating '093be8ad-801f-4cc1-92e8-05e10502e829' in the Jenkins web interface, not by code

                withEnv(["PATH+=$JMETER_HOME/bin", 'CHROME_HEADLESS_MODE=true', "APP_URL=$HXC_URL", "CHROME_DRIVER_PATH=${readJSON(file: "$Webdrivers\\update-config.json").chrome.last}","DATA_CREATION_USERNAME=bob","DATA_CREATION_USERPWD=wstinol2019","DATA_CREATION_USERSCOPE=hxp","TENANT_ID=faculty-ad6a0b45-7fba-4466-ba64-11e6e4082c9d"]) {
                  echo "Using Chrome Webdriver: $CHROME_DRIVER_PATH"
                  echo "Using Jmeter Home: $JMETER_HOME"
                  powershell label: 'java version', script: 'Get-Command java | Select-Object Version'
                  script {
                    powershell label: 'Install npm package dependency', script: '''
                                          pushd src
                                          npm ci
                                          '''

                  }

                  script {
                     timeout(1000) {
                         powershell label: 'Run test case: common-user-actions-single-user-50docs-10pgs', script: '''
                         pushd src
                         npm test suiteName=common-user-actions-single-user-50docs-10pgs testName=common-user-actions numberOfUsers=1 rampup=10
                         popd
                         '''
                     }
                    // timeout(100) {
                    //     powershell label: 'Run test case: common-user-actions-multi-user-50docs-10pgs', script: '''
                    //     pushd src
                    //     npm test suiteName=common-user-actions-multi-user-50docs-10pgs testName=common-user-actions numberOfUsers=10 rampup=30
                    //     popd
                    //     '''
                    // }
                    // timeout(100) {
                    //     powershell label: 'Run test case: last-page-navigation-10000batch', script: '''
                    //     pushd src
                    //     npm test suiteName=last-page-navigation-10000batch testName=last-page-navigation numberOfUsers=1 rampup=10
                    //     popd
                    //     '''
                    //  }
                    timeout(100) {
                        powershell label: 'Run test case: content-queue-navigation', script: '''
                        pushd src
                        npm test suiteName=content-queue-navigation testName=content-queue-navigation numberOfUsers=1 rampup=10
                        popd
                        '''
                    }
                    powershell label: 'Copy dependencies', script: "Copy-Item -Path src\\*.jtl -force"
                  }
                }
                }
              post {
                always {
                  script {
                    def timeLimits = readYaml(file: 'src/baseline/config.yml').tests
                .findAll({ n, d -> d && d.threshold })
                .collect({ n, d -> "${n}.jtl:${d.threshold * d.Withbuffer as int}"  } )
                .join('\n')
                    echo "Enforced Time Limits (ms)\n---\n$timeLimits" // log our timing thresholds
                    //Archive artifacts
                    archiveArtifacts artifacts: '/src/*.log' // JMeter log file(s); for debugging purposes
                    archiveArtifacts artifacts: '/src/*.jtl', allowEmptyArchive: true // the actual performance data
                    // Archive error screenshots
                    archiveArtifacts artifacts: '/src/screenshots/*.*', allowEmptyArchive: true

                    //display report
                    perfReport \
                  sourceDataFiles: '*.jtl',
                  compareBuildPrevious: true,
                  errorFailedThreshold: 1,
                  errorUnstableResponseTimeThreshold: timeLimits
                    
                // It *is* possible for `perfReport` to throw, in which case we want this to remain false.
              	// That's also the primary motivation behind making it part of the global state rather than a parameter for `MessageMattermost()`.
              		State.haveReport = true

                    // send status notification via Mattermost
                    def status = [
                      SUCCESS:  [color: MATTERMOST_GREEN,  message: '**Rejoice!** Performance was satisfactory.' ],
                      UNSTABLE: [color: MATTERMOST_YELLOW, message: '@all Performance was **unsatisfactory**.'   ],
                      FAILURE:  [color: MATTERMOST_RED,    message: '@all One or more performance tests **failed with errors**.'],
                    ][currentBuild.result]
                    MessageMattermost(SEND_FOR_MASTER_ONLY, status.color, status.message)
                  }
                }
                aborted {
                  MessageMattermost(SEND_FOR_MASTER_ONLY, MATTERMOST_YELLOW, '@all Performance tests **did not finish** due to 10 hour timeout (or manual abort)!')
                }
                // success {
                //   node(label: MongoDBAgentLabel) {
                //     // the various services we started earlier will also be used for manual performance testing
                //     // to give testers a clean platform, we need to clear out mongo; everything else can keep running
                //     StartPlatformService('mongoserver', '--renew-anon-volumes', 'mongod --version', false)
                //     cleanWs()
                //   }
                // }
                failure {
                  script {                    
                      MessageMattermost(SEND_FOR_MASTER_ONLY, MATTERMOST_RED, '@all Performance tests **did not run** successfully!')                   
                  }
                }
              }
              }
            }
          }
        }
      post {
        cleanup {
          cleanWs()
        }
      }
      }
    }
  post {
    unsuccessful {
      script {
        if (currentBuild.result != ABORTED && !State.notified) {
          MessageMattermost(SEND_FOR_MASTER_ONLY, MATTERMOST_RED, '@all The performance pipeline is **broken**!')
        }
      }
    }
  }
  }

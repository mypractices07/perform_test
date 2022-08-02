
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


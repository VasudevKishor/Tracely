# Backend Go Functions and Methods

Generated: 2026-02-03

## config/config.go
- L24: `func Load() *Config {`
- L49: `func getEnv(key, defaultValue string) string {`

## database/database.go
- L14: `func InitDB(cfg *config.Config) (*gorm.DB, error) {`
- L45: `func CloseDB(db *gorm.DB) {`
- L57: `func RunMigrations(db *gorm.DB) error {`
- L95: `func createIndexes(db *gorm.DB) {`

## handlers/alert_handler.go
- L16: `func NewAlertHandler(alertingService *services.AlertingService) *AlertHandler {`
- L28: `func (h *AlertHandler) CreateRule(c *gin.Context) {`
- L51: `func (h *AlertHandler) GetActiveAlerts(c *gin.Context) {`
- L63: `func (h *AlertHandler) AcknowledgeAlert(c *gin.Context) {`

## handlers/auth_handler.go
- L102: `func (h *AuthHandler) VerifyToken(c *gin.Context) {`
- L14: `func NewAuthHandler(authService *services.AuthService) *AuthHandler {`
- L29: `func (h *AuthHandler) Login(c *gin.Context) {`
- L52: `func (h *AuthHandler) Register(c *gin.Context) {`
- L76: `func (h *AuthHandler) Logout(c *gin.Context) {`
- L84: `func (h *AuthHandler) RefreshToken(c *gin.Context) {`

## handlers/collection_handler.go
- L105: `func (h *CollectionHandler) Delete(c *gin.Context) {`
- L16: `func NewCollectionHandler(collectionService *services.CollectionService) *CollectionHandler {`
- L25: `func (h *CollectionHandler) Create(c *gin.Context) {`
- L48: `func (h *CollectionHandler) GetAll(c *gin.Context) {`
- L65: `func (h *CollectionHandler) GetByID(c *gin.Context) {`
- L82: `func (h *CollectionHandler) Update(c *gin.Context) {`

## handlers/governance_handler.go
- L16: `func NewGovernanceHandler(governanceService *services.GovernanceService) *GovernanceHandler {`
- L27: `func (h *GovernanceHandler) GetPolicies(c *gin.Context) {`
- L44: `func (h *GovernanceHandler) CreatePolicy(c *gin.Context) {`
- L67: `func (h *GovernanceHandler) UpdatePolicy(c *gin.Context) {`
- L90: `func (h *GovernanceHandler) DeletePolicy(c *gin.Context) {`

## handlers/loadtest_handler.go
- L16: `func NewLoadTestHandler(loadTestService *services.LoadTestService) *LoadTestHandler {`
- L28: `func (h *LoadTestHandler) Create(c *gin.Context) {`

## handlers/mock_handler.go
- L16: `func NewMockHandler(mockService *services.MockService) *MockHandler {`
- L24: `func (h *MockHandler) GenerateFromTrace(c *gin.Context) {`
- L53: `func (h *MockHandler) GetAll(c *gin.Context) {`
- L70: `func (h *MockHandler) Update(c *gin.Context) {`
- L93: `func (h *MockHandler) Delete(c *gin.Context) {`

## handlers/monitoring_handler.go
- L16: `func NewMonitoringHandler(monitoringService *services.MonitoringService) *MonitoringHandler {`
- L20: `func (h *MonitoringHandler) GetDashboard(c *gin.Context) {`
- L39: `func (h *MonitoringHandler) GetMetrics(c *gin.Context) {`
- L46: `func (h *MonitoringHandler) GetTopology(c *gin.Context) {`

## handlers/replay_handler.go
- L100: `func (h *ReplayHandler) GetResults(c *gin.Context) {`
- L16: `func NewReplayHandler(replayService *services.ReplayService) *ReplayHandler {`
- L28: `func (h *ReplayHandler) CreateReplay(c *gin.Context) {`
- L66: `func (h *ReplayHandler) GetReplay(c *gin.Context) {`
- L83: `func (h *ReplayHandler) ExecuteReplay(c *gin.Context) {`

## handlers/request_handler.go
- L110: `func (h *RequestHandler) Delete(c *gin.Context) {`
- L132: `func (h *RequestHandler) Execute(c *gin.Context) {`
- L161: `func (h *RequestHandler) GetHistory(c *gin.Context) {`
- L18: `func NewRequestHandler(requestService *services.RequestService) *RequestHandler {`
- L32: `func (h *RequestHandler) Create(c *gin.Context) {`
- L70: `func (h *RequestHandler) GetByID(c *gin.Context) {`
- L87: `func (h *RequestHandler) Update(c *gin.Context) {`

## handlers/secrets_handler.go
- L16: `func NewSecretsHandler(secretsService *services.SecretsService) *SecretsHandler {`
- L26: `func (h *SecretsHandler) Create(c *gin.Context) {`
- L48: `func (h *SecretsHandler) GetValue(c *gin.Context) {`
- L65: `func (h *SecretsHandler) Rotate(c *gin.Context) {`

## handlers/settings_handler.go
- L15: `func NewSettingsHandler(settingsService *services.SettingsService) *SettingsHandler {`
- L19: `func (h *SettingsHandler) GetSettings(c *gin.Context) {`
- L31: `func (h *SettingsHandler) UpdateSettings(c *gin.Context) {`

## handlers/trace_handler.go
- L104: `func (h *TraceHandler) GetCriticalPath(c *gin.Context) {`
- L18: `func NewTraceHandler(traceService *services.TraceService) *TraceHandler {`
- L22: `func (h *TraceHandler) GetTraces(c *gin.Context) {`
- L56: `func (h *TraceHandler) GetTraceDetails(c *gin.Context) {`
- L81: `func (h *TraceHandler) AddAnnotation(c *gin.Context) {`

## handlers/workflow_handler.go
- L16: `func NewWorkflowHandler(workflowService *services.WorkflowService) *WorkflowHandler {`
- L26: `func (h *WorkflowHandler) Create(c *gin.Context) {`
- L48: `func (h *WorkflowHandler) Execute(c *gin.Context) {`

## handlers/workspace_handler.go
- L113: `func (h *WorkspaceHandler) Delete(c *gin.Context) {`
- L16: `func NewWorkspaceHandler(workspaceService *services.WorkspaceService) *WorkspaceHandler {`
- L25: `func (h *WorkspaceHandler) Create(c *gin.Context) {`
- L47: `func (h *WorkspaceHandler) GetAll(c *gin.Context) {`
- L63: `func (h *WorkspaceHandler) GetByID(c *gin.Context) {`
- L85: `func (h *WorkspaceHandler) Update(c *gin.Context) {`

## integrations/cicd_integration.go
- L13: `func NewCICDIntegration(webhookURL string) *CICDIntegration {`
- L17: `func (c *CICDIntegration) TriggerPipeline(repoName, branch string, tests []string) error {`

## integrations/cloudwatch_integration.go
- L17: `func NewCloudWatchIntegration(cfg aws.Config, namespace string) *CloudWatchIntegration {`
- L25: `func (c *CloudWatchIntegration) PutMetric(metricName string, value float64, unit types.StandardUnit, dimensions map[string]string) error {`
- L51: `func (c *CloudWatchIntegration) GetMetricStatistics(metricName string, start, end time.Time, period int32, statistic types.Statistic) ([]types.Datapoint, error) {`

## integrations/pagerduty_integration.go
- L14: `func NewPagerDutyIntegration(integrationKey string) *PagerDutyIntegration {`
- L22: `func (p *PagerDutyIntegration) TriggerIncident(summary, severity, source string) error {`
- L49: `func (p *PagerDutyIntegration) ResolveIncident(dedupKey string) error {`

## integrations/postman_importer.go
- L38: `func NewPostmanImporter() *PostmanImporter {`
- L42: `func (p *PostmanImporter) ImportFromFile(filepath string) (*PostmanCollection, error) {`
- L56: `func (p *PostmanImporter) ConvertToRequests(collection *PostmanCollection) []map[string]interface{} {`

## integrations/prometheus_integration.go
- L15: `func NewPrometheusIntegration(baseURL string) *PrometheusIntegration {`
- L23: `func (p *PrometheusIntegration) QueryRange(query string, start, end time.Time, step string) ([]MetricPoint, error) {`
- L71: `func (p *PrometheusIntegration) CorrelateWithTrace(traceID string, start, end time.Time) (map[string][]MetricPoint, error) {`

## integrations/slack_integration.go
- L13: `func NewSlackIntegration(webhookURL string) *SlackIntegration {`
- L17: `func (s *SlackIntegration) SendMessage(message string) error {`
- L32: `func (s *SlackIntegration) SendAlert(title, message, severity string) error {`

## main.go
- L102: `func setupRouter(cfg *config.Config, authService *services.AuthService,`
- L24: `func main() {`

## middlewares/auth.go
- L13: `func AuthMiddleware(authService *services.AuthService) gin.HandlerFunc {`
- L61: `func GetUserID(c *gin.Context) (uuid.UUID, error) {`

## middlewares/error.go
- L10: `func ErrorHandler() gin.HandlerFunc {`

## middlewares/graphql_wrapper.go
- L15: `func GraphQLMiddleware(next http.Handler) http.Handler {`
- L35: `func GetTraceIDFromContext(ctx context.Context) string {`

## middlewares/grpc_interceptor.go
- L12: `func GRPCUnaryInterceptor() grpc.UnaryServerInterceptor {`
- L29: `func GRPCStreamInterceptor() grpc.StreamServerInterceptor {`
- L44: `func extractGRPCTraceID(ctx context.Context) string {`
- L59: `func (w *wrappedStream) Context() context.Context {`

## middlewares/logger.go
- L10: `func RequestLogger() gin.HandlerFunc {`

## middlewares/trace.go
- L8: `func TraceID() gin.HandlerFunc {`

## services/alerting_service.go
- L101: `func (s *AlertingService) CheckErrorRate(workspaceID uuid.UUID) error {`
- L146: `func (s *AlertingService) TriggerAlert(ruleID, workspaceID uuid.UUID, severity, message string, metadata map[string]interface{}) error {`
- L184: `func (s *AlertingService) SendSlackNotification(alert *Alert, rule *AlertRule) error {`
- L192: `func (s *AlertingService) SendEmailNotification(alert *Alert, rule *AlertRule) error {`
- L199: `func (s *AlertingService) SendPagerDutyNotification(alert *Alert, rule *AlertRule) error {`
- L206: `func (s *AlertingService) AcknowledgeAlert(alertID uuid.UUID) error {`
- L211: `func (s *AlertingService) ResolveAlert(alertID uuid.UUID) error {`
- L220: `func (s *AlertingService) GetActiveAlerts(workspaceID uuid.UUID) ([]Alert, error) {`
- L44: `func NewAlertingService(db *gorm.DB) *AlertingService {`
- L49: `func (s *AlertingService) CreateRule(userID uuid.UUID, workspaceID uuid.UUID, name, condition string, threshold float64, timeWindow int, channel string) (*AlertRule, error) {`
- L69: `func (s *AlertingService) CheckLatencyThreshold(workspaceID uuid.UUID) error {`

## services/audit_service.go
- L30: `func NewAuditService(db *gorm.DB) *AuditService {`
- L35: `func (s *AuditService) Log(workspaceID, userID, resourceID uuid.UUID, action, resourceType, ipAddress, userAgent string, changes map[string]interface{}, success bool, errorMsg string) error {`
- L56: `func (s *AuditService) GetLogs(workspaceID uuid.UUID, filters map[string]interface{}, limit, offset int) ([]AuditLog, error) {`
- L75: `func (s *AuditService) DetectAnomalies(workspaceID, userID uuid.UUID) ([]string, error) {`

## services/auth_service.go
- L121: `func (s *AuthService) GenerateToken(userID uuid.UUID, email string) (string, error) {`
- L142: `func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {`
- L160: `func (s *AuthService) GenerateRefreshToken(userID uuid.UUID) (string, error) {`
- L177: `func (s *AuthService) RefreshAccessToken(refreshToken string) (string, error) {`
- L202: `func (s *AuthService) RevokeRefreshToken(refreshToken string) error {`
- L32: `func NewAuthService(db *gorm.DB, cfg *config.Config) *AuthService {`
- L39: `func (s *AuthService) Register(email, password, name string) (*models.User, *TokenPair, error) {`
- L95: `func (s *AuthService) Login(email, password string) (*models.User, *TokenPair, error) {`

## services/collection_service.go
- L16: `func NewCollectionService(db *gorm.DB) *CollectionService {`
- L23: `func (s *CollectionService) Create(workspaceID uuid.UUID, name, description string, userID uuid.UUID) (*models.Collection, error) {`
- L41: `func (s *CollectionService) GetAll(workspaceID, userID uuid.UUID) ([]models.Collection, error) {`
- L51: `func (s *CollectionService) GetByID(collectionID, userID uuid.UUID) (*models.Collection, error) {`
- L64: `func (s *CollectionService) Update(collectionID, userID uuid.UUID, name, description string) (*models.Collection, error) {`
- L84: `func (s *CollectionService) Delete(collectionID, userID uuid.UUID) error {`

## services/failure_injection_service.go
- L29: `func NewFailureInjectionService(db *gorm.DB) *FailureInjectionService {`
- L34: `func (s *FailureInjectionService) InjectFailure(workspaceID uuid.UUID, req *http.Request) error {`
- L59: `func (s *FailureInjectionService) injectTimeout(rule FailureInjectionRule) error {`
- L65: `func (s *FailureInjectionService) injectError(rule FailureInjectionRule) error {`
- L75: `func (s *FailureInjectionService) injectLatency(rule FailureInjectionRule) error {`
- L85: `func (s *FailureInjectionService) injectUnavailable(rule FailureInjectionRule) error {`
- L90: `func (s *FailureInjectionService) CreateRule(workspaceID uuid.UUID, name, failureType string, probability float64, config map[string]interface{}) (*FailureInjectionRule, error) {`

## services/governance_service.go
- L16: `func NewGovernanceService(db *gorm.DB) *GovernanceService {`
- L23: `func (s *GovernanceService) GetPolicies(workspaceID, userID uuid.UUID) ([]models.Policy, error) {`
- L33: `func (s *GovernanceService) CreatePolicy(workspaceID, userID uuid.UUID, name, description, rules string, enabled bool) (*models.Policy, error) {`
- L53: `func (s *GovernanceService) UpdatePolicy(policyID, userID uuid.UUID, updates map[string]interface{}) (*models.Policy, error) {`
- L70: `func (s *GovernanceService) DeletePolicy(policyID, userID uuid.UUID) error {`

## services/load_test_service.go
- L36: `func NewLoadTestService(db *gorm.DB) *LoadTestService {`
- L43: `func (s *LoadTestService) CreateLoadTest(workspaceID, requestID, userID uuid.UUID, name string, concurrency, totalRequests, rampUp int) (*LoadTest, error) {`
- L65: `func (s *LoadTestService) executeLoadTest(testID, userID uuid.UUID) {`

## services/mock_service.go
- L112: `func (s *MockService) Delete(mockID, userID uuid.UUID) error {`
- L18: `func NewMockService(db *gorm.DB) *MockService {`
- L26: `func (s *MockService) GenerateFromTrace(workspaceID, userID, traceID uuid.UUID) ([]*models.Mock, error) {`
- L85: `func (s *MockService) GetAll(workspaceID, userID uuid.UUID) ([]models.Mock, error) {`
- L95: `func (s *MockService) Update(mockID, userID uuid.UUID, updates map[string]interface{}) (*models.Mock, error) {`

## services/monitoring_service.go
- L119: `func (s *MonitoringService) GetTopology(workspaceID, userID uuid.UUID) (map[string]interface{}, error) {`
- L175: `func contains(slice []string, item string) bool {`
- L29: `func NewMonitoringService(db *gorm.DB) *MonitoringService {`
- L36: `func (s *MonitoringService) GetDashboard(workspaceID, userID uuid.UUID, timeRange string) (*DashboardData, error) {`

## services/mutation_service.go
- L19: `func NewMutationService() *MutationService {`
- L24: `func (s *MutationService) ApplyMutations(url, body string, headers map[string]string, rules []MutationRule, variables map[string]string) (string, string, map[string]string, error) {`
- L46: `func (s *MutationService) applyReplace(url, body string, headers map[string]string, rule MutationRule) (string, string, map[string]string) {`
- L60: `func (s *MutationService) applyRegex(url, body string, headers map[string]string, rule MutationRule) (string, string, map[string]string) {`
- L76: `func (s *MutationService) applyTemplate(url, body string, headers map[string]string, rule MutationRule, variables map[string]string) (string, string, map[string]string) {`

## services/percentile_calculator.go
- L11: `func NewPercentileCalculator() *PercentileCalculator {`
- L16: `func (p *PercentileCalculator) Calculate(values []int64, percentile float64) float64 {`
- L43: `func (p *PercentileCalculator) CalculatePercentiles(values []int64, percentiles []float64) map[string]float64 {`

## services/replay_service.go
- L109: `func (s *ReplayService) GetResults(replayID, userID uuid.UUID) ([]models.ReplayExecution, error) {`
- L19: `func NewReplayService(db *gorm.DB) *ReplayService {`
- L27: `func (s *ReplayService) CreateReplay(workspaceID, userID uuid.UUID, name, description string, sourceTraceID uuid.UUID, targetEnv string, config map[string]interface{}) (*models.Replay, error) {`
- L52: `func (s *ReplayService) GetReplay(replayID, userID uuid.UUID) (*models.Replay, error) {`
- L65: `func (s *ReplayService) ExecuteReplay(replayID, userID uuid.UUID) (*models.ReplayExecution, error) {`

## services/request_service.go
- L173: `func (s *RequestService) GetHistory(requestID, userID uuid.UUID, limit, offset int) ([]models.Execution, int64, error) {`
- L21: `func NewRequestService(db *gorm.DB) *RequestService {`
- L28: `func (s *RequestService) Create(collectionID uuid.UUID, name, method, url, headers, queryParams, body, description string, userID uuid.UUID) (*models.Request, error) {`
- L59: `func (s *RequestService) GetByID(requestID, userID uuid.UUID) (*models.Request, error) {`
- L72: `func (s *RequestService) Update(requestID, userID uuid.UUID, updates map[string]interface{}) (*models.Request, error) {`
- L85: `func (s *RequestService) Delete(requestID, userID uuid.UUID) error {`
- L94: `func (s *RequestService) Execute(requestID, userID uuid.UUID, overrideURL string, overrideHeaders map[string]string, traceID uuid.UUID) (*models.Execution, error) {`

## services/schema_validator.go
- L14: `func (s *SchemaValidator) ValidateAgainstOpenAPI(responseBody string, schemaJSON string) (*ValidationResult, error) {`
- L42: `func (s *SchemaValidator) ValidateContract(request, response string, contract Contract) (*ValidationResult, error) {`
- L9: `func NewSchemaValidator() *SchemaValidator {`

## services/secrets_service.go
- L120: `func (s *SecretsService) GetSecret(secretID, workspaceID uuid.UUID) (string, error) {`
- L134: `func (s *SecretsService) RotateSecret(secretID, workspaceID uuid.UUID, newValue string) error {`
- L33: `func NewSecretsService(db *gorm.DB, key string) *SecretsService {`
- L48: `func (s *SecretsService) encrypt(plaintext string) (string, error) {`
- L68: `func (s *SecretsService) decrypt(ciphertext string) (string, error) {`
- L98: `func (s *SecretsService) CreateSecret(workspaceID, userID uuid.UUID, key, value, description string) (*Secret, error) {`

## services/session_service.go
- L25: `func NewSessionService(db *gorm.DB) *SessionService {`
- L30: `func (s *SessionService) CaptureSession(workspaceID uuid.UUID, name string, cookies map[string]string, tokens map[string]string) (*Session, error) {`
- L54: `func (s *SessionService) GetSession(sessionID uuid.UUID) (map[string]interface{}, error) {`
- L67: `func (s *SessionService) ApplySession(sessionID uuid.UUID, req *http.Request) error {`

## services/settings_service.go
- L15: `func NewSettingsService(db *gorm.DB) *SettingsService {`
- L19: `func (s *SettingsService) GetSettings(userID uuid.UUID) (*models.UserSettings, error) {`
- L41: `func (s *SettingsService) UpdateSettings(userID uuid.UUID, updates map[string]interface{}) (*models.UserSettings, error) {`

## services/testdata_generator.go
- L128: `func (g *TestDataGenerator) generateInteger(schema map[string]interface{}) int {`
- L13: `func NewTestDataGenerator() *TestDataGenerator {`
- L142: `func (g *TestDataGenerator) generateNumber(schema map[string]interface{}) float64 {`
- L156: `func (g *TestDataGenerator) generateBoolean() bool {`
- L161: `func (g *TestDataGenerator) GenerateRealisticData(dataType string) interface{} {`
- L19: `func (g *TestDataGenerator) GenerateFromSchema(schemaJSON string) (string, error) {`
- L30: `func (g *TestDataGenerator) generateFromSchemaObject(schema map[string]interface{}) interface{} {`
- L54: `func (g *TestDataGenerator) generateObject(schema map[string]interface{}) map[string]interface{} {`
- L68: `func (g *TestDataGenerator) generateArray(schema map[string]interface{}) []interface{} {`
- L91: `func (g *TestDataGenerator) generateString(schema map[string]interface{}) string {`

## services/trace_service.go
- L114: `func (s *TraceService) AddAnnotation(spanID, userID uuid.UUID, comment string, highlight bool) (*models.Annotation, error) {`
- L129: `func (s *TraceService) GetCriticalPath(traceID, userID uuid.UUID) ([]models.Span, error) {`
- L144: `func (s *TraceService) findCriticalPath(spans []models.Span) []models.Span {`
- L18: `func NewTraceService(db *gorm.DB) *TraceService {`
- L191: `func calculateTotalDuration(spans []models.Span) float64 {`
- L25: `func (s *TraceService) CreateTrace(workspaceID uuid.UUID, serviceName string, status string) (*models.Trace, error) {`
- L40: `func (s *TraceService) AddSpan(traceID uuid.UUID, parentSpanID *uuid.UUID, operationName, serviceName string, durationMs float64, tags, logs map[string]interface{}) (*models.Span, error) {`
- L70: `func (s *TraceService) GetTraces(workspaceID, userID uuid.UUID, serviceName string, startTime, endTime *time.Time, limit, offset int) ([]models.Trace, int64, error) {`
- L98: `func (s *TraceService) GetTraceDetails(traceID, userID uuid.UUID) (*models.Trace, []models.Span, error) {`

## services/waterfall_service.go
- L31: `func NewWaterfallService(db *gorm.DB) *WaterfallService {`
- L36: `func (s *WaterfallService) GenerateWaterfall(traceID uuid.UUID) (*WaterfallNode, error) {`
- L66: `func (s *WaterfallService) buildWaterfallNode(span *models.Span, spanMap map[uuid.UUID]*models.Span, traceStart time.Time, depth int) *WaterfallNode {`

## services/webhook_service.go
- L104: `func (s *WebhookService) sendWebhook(webhook *Webhook, event *WebhookEvent) {`
- L38: `func NewWebhookService(db *gorm.DB) *WebhookService {`
- L43: `func (s *WebhookService) CreateWebhook(workspaceID uuid.UUID, name, url, secret string, events []string) (*Webhook, error) {`
- L64: `func (s *WebhookService) TriggerWebhook(workspaceID uuid.UUID, eventType string, payload map[string]interface{}) error {`

## services/workflow_service.go
- L113: `func (s *WorkflowService) executeSteps(executionID uuid.UUID, steps []WorkflowStep, userID uuid.UUID, context map[string]interface{}) {`
- L151: `func (s *WorkflowService) updateExecutionStatus(executionID uuid.UUID, status, errorMsg string) {`
- L53: `func NewWorkflowService(db *gorm.DB) *WorkflowService {`
- L60: `func (s *WorkflowService) CreateWorkflow(workspaceID, userID uuid.UUID, name, description string, steps []WorkflowStep) (*Workflow, error) {`
- L83: `func (s *WorkflowService) ExecuteWorkflow(workflowID, userID uuid.UUID) (*WorkflowExecution, error) {`

## services/workspace_service.go
- L113: `func (s *WorkspaceService) HasAccess(workspaceID, userID uuid.UUID) bool {`
- L121: `func (s *WorkspaceService) IsAdmin(workspaceID, userID uuid.UUID) bool {`
- L129: `func (s *WorkspaceService) AddMember(workspaceID, userID, memberUserID uuid.UUID, role string) error {`
- L143: `func (s *WorkspaceService) RemoveMember(workspaceID, userID, memberUserID uuid.UUID) error {`
- L15: `func NewWorkspaceService(db *gorm.DB) *WorkspaceService {`
- L19: `func (s *WorkspaceService) Create(name, description string, ownerID uuid.UUID) (*models.Workspace, error) {`
- L43: `func (s *WorkspaceService) GetAll(userID uuid.UUID) ([]models.Workspace, error) {`
- L57: `func (s *WorkspaceService) GetByID(workspaceID, userID uuid.UUID) (*models.Workspace, error) {`
- L77: `func (s *WorkspaceService) Update(workspaceID, userID uuid.UUID, name, description string) (*models.Workspace, error) {`
- L99: `func (s *WorkspaceService) Delete(workspaceID, userID uuid.UUID) error {`

## utils/pii_masker.go
- L107: `func (m *PIIMasker) MaskHeaders(headers map[string]string) map[string]string {`
- L12: `func NewPIIMasker() *PIIMasker {`
- L28: `func (m *PIIMasker) MaskString(input string) string {`
- L63: `func (m *PIIMasker) MaskJSON(jsonStr string) string {`
- L84: `func (m *PIIMasker) DetectPII(input string) []string {`

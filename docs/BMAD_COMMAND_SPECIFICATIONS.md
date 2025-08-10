# BMAD-METHOD Command Specifications

**Document Type**: Technical Command Specification  
**Version**: 1.0  
**Created**: August 10, 2025  
**Status**: Design Specification  

## Overview

Complete specification for BMAD-METHOD integrated commands within The Hive's SuperClaude framework. This document provides detailed technical specifications for each command, including parameters, workflows, validation gates, and integration patterns.

## 🚀 Core BMAD Commands

### `/sc:bmad-init`
**Initialize BMAD methodology framework for projects**

#### Command Definition
```yaml
---
command: "/sc:bmad-init"
category: "Methodology & Initialization"
purpose: "Initialize BMAD methodology framework for projects with team coordination"
wave-enabled: true
performance-profile: "standard"
persona-activation: ["architect", "mentor", "scribe"]
mcp-integration: ["bmad-docs", "context7", "sequential"]
---
```

#### Syntax
```bash
/sc:bmad-init [project-type] [flags]
```

#### Parameters
```yaml
project-type:
  options: ["web-app", "api", "microservice", "mobile-app", "desktop-app", "library", "cli-tool"]
  default: "auto-detect"
  description: "Project type for methodology customization"

flags:
  --interactive: "Guided setup with step-by-step prompts"
  --team-size: "Number of team members (affects collaboration patterns)"
  --complexity: "Project complexity level [low|medium|high|enterprise]"
  --existing-project: "Apply BMAD methodology to existing codebase"
  --methodology-migration: "Migrate from another methodology framework"
  --quick-setup: "Automated setup with sensible defaults"
  --custom-templates: "Use custom BMAD templates"
  --git-integration: "Initialize with Git workflow integration"
```

#### Workflow Phases
```yaml
phase-1-discovery:
  tasks:
    - "Project structure analysis"
    - "Team composition assessment"  
    - "Existing methodology evaluation"
    - "Complexity estimation"
  outputs:
    - "Project classification"
    - "Team coordination strategy"
    - "Methodology customization plan"

phase-2-initialization:
  tasks:
    - "BMAD directory structure creation"
    - "Template application and customization"
    - "Tool integration setup"
    - "Team onboarding materials generation"
  outputs:
    - "BMAD project structure"
    - "Customized templates"
    - "Integration configurations"
    - "Onboarding documentation"

phase-3-validation:
  tasks:
    - "Structure validation"
    - "Template consistency check"
    - "Integration testing"
    - "Team readiness assessment"
  outputs:
    - "Validation report"
    - "Setup recommendations"
    - "Next steps guidance"
```

#### Quality Gates
- **Structure Validation**: BMAD directory structure compliance
- **Template Consistency**: Template application accuracy
- **Tool Integration**: External tool compatibility verification
- **Team Readiness**: Team capability and training assessment

#### Usage Examples
```bash
# Interactive guided setup
/sc:bmad-init --interactive

# Specific project type with team configuration
/sc:bmad-init web-app --team-size 8 --complexity high --git-integration

# Existing project methodology migration
/sc:bmad-init --existing-project --methodology-migration --complexity medium

# Quick setup for small projects
/sc:bmad-init api --quick-setup --team-size 3
```

---

### `/sc:bmad-analyze`
**Comprehensive BMAD-compliant analysis with methodology validation**

#### Command Definition
```yaml
---
command: "/sc:bmad-analyze"
category: "Analysis & Assessment"
purpose: "Multi-dimensional BMAD methodology analysis with collective intelligence"
wave-enabled: true
performance-profile: "complex"
persona-activation: ["analyzer", "architect", "security", "performance"]
mcp-integration: ["bmad-docs", "sequential", "context7"]
---
```

#### Syntax
```bash
/sc:bmad-analyze [scope] [flags]
```

#### Parameters
```yaml
scope:
  options: ["project", "module", "component", "architecture", "documentation", "processes"]
  default: "project"
  description: "Analysis scope and focus area"

flags:
  --depth: "Analysis depth [surface|standard|deep|comprehensive]"
  --focus: "Analysis focus areas [best-practices|methodology|architecture|documentation|security|performance]"
  --output-format: "Report format [markdown|html|pdf|json|interactive]"
  --baseline: "Compare against BMAD baseline standards"
  --historical: "Include historical analysis and trends"
  --team-impact: "Include team process and collaboration analysis"
  --actionable-insights: "Generate specific improvement recommendations"
  --compliance-check: "Check compliance against specific standards"
```

#### Analysis Dimensions
```yaml
best-practices-analysis:
  code-quality:
    metrics: ["complexity", "maintainability", "readability", "testability"]
    patterns: ["design-patterns", "anti-patterns", "code-smells"]
    standards: ["coding-conventions", "style-guides", "naming-conventions"]
  
  security-analysis:
    vulnerabilities: ["static-analysis", "dependency-check", "configuration-review"]
    patterns: ["security-patterns", "authentication", "authorization", "data-protection"]
    compliance: ["owasp-top-10", "security-standards", "privacy-regulations"]
  
  performance-analysis:
    metrics: ["response-time", "throughput", "resource-usage", "scalability"]
    patterns: ["optimization-patterns", "caching-strategies", "database-efficiency"]
    bottlenecks: ["code-bottlenecks", "architecture-constraints", "infrastructure-limits"]

methodology-analysis:
  process-compliance:
    workflows: ["development-process", "review-process", "deployment-process"]
    quality-gates: ["validation-completeness", "testing-coverage", "documentation-quality"]
    team-coordination: ["communication-patterns", "knowledge-sharing", "collaboration-efficiency"]
  
  tool-integration:
    development-tools: ["ide-configuration", "build-tools", "testing-frameworks"]
    collaboration-tools: ["version-control", "project-management", "communication-platforms"]
    automation: ["ci-cd-pipelines", "testing-automation", "deployment-automation"]

architecture-analysis:
  design-quality:
    principles: ["solid-principles", "clean-architecture", "domain-driven-design"]
    patterns: ["architectural-patterns", "integration-patterns", "data-patterns"]
    decisions: ["architecture-decisions", "trade-off-analysis", "technical-debt"]
  
  scalability-assessment:
    horizontal-scaling: ["load-distribution", "stateless-design", "microservices-readiness"]
    vertical-scaling: ["resource-optimization", "performance-tuning", "caching-strategies"]
    resilience: ["fault-tolerance", "disaster-recovery", "monitoring-observability"]

documentation-analysis:
  coverage-assessment:
    technical-documentation: ["api-documentation", "architecture-documentation", "deployment-guides"]
    user-documentation: ["user-guides", "tutorials", "troubleshooting-guides"]
    process-documentation: ["development-processes", "operational-procedures", "team-guidelines"]
  
  quality-metrics:
    accuracy: ["content-accuracy", "technical-correctness", "up-to-date-status"]
    accessibility: ["readability", "searchability", "multi-format-availability"]
    maintenance: ["update-frequency", "review-process", "automated-generation"]
```

#### Workflow Implementation
```yaml
wave-1-discovery:
  tasks:
    - "Project structure analysis"
    - "Codebase pattern recognition"
    - "Team process assessment"
    - "Tool integration evaluation"
  tools: ["Read", "Grep", "Glob", "bmad-docs"]
  outputs: ["analysis-baseline", "pattern-catalog", "process-map"]

wave-2-analysis:
  tasks:
    - "Multi-dimensional quality assessment"
    - "Best practice compliance checking"
    - "Architecture decision evaluation"
    - "Documentation quality analysis"
  tools: ["sequential", "context7", "bmad-docs"]
  outputs: ["quality-metrics", "compliance-report", "gap-analysis"]

wave-3-synthesis:
  tasks:
    - "Cross-dimensional correlation analysis"
    - "Priority ranking of issues and opportunities"
    - "Actionable improvement roadmap generation"
    - "Resource estimation and planning"
  tools: ["sequential", "Write", "TodoWrite"]
  outputs: ["synthesis-report", "improvement-roadmap", "implementation-plan"]

wave-4-validation:
  tasks:
    - "Analysis accuracy validation"
    - "Recommendation feasibility assessment"
    - "Team impact evaluation"
    - "Success metrics definition"
  tools: ["sequential", "bmad-docs"]
  outputs: ["validated-analysis", "implementation-guide", "success-metrics"]
```

#### Quality Gates
- **Analysis Completeness**: All requested dimensions analyzed
- **Accuracy Validation**: Analysis accuracy against known benchmarks
- **Actionability**: Specific, measurable improvement recommendations
- **Feasibility**: Implementation feasibility assessment

#### Usage Examples
```bash
# Comprehensive project analysis
/sc:bmad-analyze project --depth comprehensive --output-format interactive

# Security-focused analysis
/sc:bmad-analyze --focus security --compliance-check --baseline

# Architecture assessment with historical trends
/sc:bmad-analyze architecture --historical --team-impact --actionable-insights

# Quick best practices check
/sc:bmad-analyze --focus best-practices --depth standard
```

---

### `/sc:bmad-implement`
**Feature implementation with BMAD methodology validation and guidance**

#### Command Definition
```yaml
---
command: "/sc:bmad-implement"
category: "Development & Implementation"
purpose: "BMAD-guided feature implementation with real-time validation and documentation"
wave-enabled: true
performance-profile: "standard"
persona-activation: ["intelligent-domain-detection", "architect", "qa"]
mcp-integration: ["bmad-docs", "context7", "sequential", "magic"]
---
```

#### Syntax
```bash
/sc:bmad-implement [feature-description] [flags]
```

#### Parameters
```yaml
feature-description:
  type: "string"
  required: true
  description: "Natural language description of feature to implement"

flags:
  --domain: "Implementation domain [frontend|backend|fullstack|api|database|infrastructure]"
  --methodology-guidance: "Enable step-by-step BMAD methodology guidance"
  --best-practices: "Apply domain-specific best practices automatically"
  --documentation-first: "Generate documentation before implementation"
  --test-driven: "Apply test-driven development approach"
  --architecture-review: "Include architecture review in implementation"
  --performance-optimized: "Apply performance optimization patterns"
  --security-hardened: "Apply security best practices"
  --compliance-check: "Check compliance against standards during implementation"
  --team-collaboration: "Enable multi-developer coordination features"
```

#### Implementation Workflow
```yaml
phase-1-discovery-and-planning:
  bmad-research:
    tasks:
      - "Best practice pattern research via Context7 and BMAD docs"
      - "Architecture pattern analysis for feature domain"
      - "Security and performance considerations research"
      - "Documentation standards and templates identification"
    outputs:
      - "Best practice catalog for feature domain"
      - "Architecture pattern recommendations"
      - "Security and performance guidelines"
      - "Documentation template selection"
  
  methodology-planning:
    tasks:
      - "Implementation strategy development with BMAD compliance"
      - "Quality gate definition and validation criteria"
      - "Documentation requirements specification"
      - "Testing strategy with coverage requirements"
    outputs:
      - "Implementation plan with methodology compliance"
      - "Quality assurance checklist"
      - "Documentation specification"
      - "Testing strategy and coverage plan"

phase-2-architecture-and-design:
  architecture-design:
    tasks:
      - "System design following BMAD architecture principles"
      - "Integration pattern definition"
      - "Data flow and interface specification"
      - "Architecture Decision Record (ADR) creation"
    outputs:
      - "Architecture design with BMAD compliance"
      - "Integration specifications"
      - "Interface definitions"
      - "ADR documentation"
  
  design-validation:
    tasks:
      - "Multi-agent architecture review"
      - "Best practice compliance validation"
      - "Performance and scalability assessment"
      - "Security design review"
    outputs:
      - "Validated architecture design"
      - "Compliance verification"
      - "Performance assessment"
      - "Security review report"

phase-3-implementation:
  guided-implementation:
    tasks:
      - "Code generation following best practices"
      - "Real-time methodology compliance checking"
      - "Progressive documentation generation"
      - "Automated testing implementation"
    tools: ["Edit", "MultiEdit", "Write", "magic", "context7"]
    outputs:
      - "Feature implementation with best practice compliance"
      - "Automated documentation updates"
      - "Comprehensive test suite"
  
  continuous-validation:
    tasks:
      - "Real-time code quality assessment"
      - "Best practice adherence monitoring"
      - "Documentation synchronization validation"
      - "Test coverage and quality verification"
    outputs:
      - "Quality metrics and compliance status"
      - "Documentation synchronization report"
      - "Test coverage report"

phase-4-validation-and-integration:
  comprehensive-validation:
    tasks:
      - "Multi-dimensional quality assessment"
      - "Integration testing and validation"
      - "Performance benchmarking"
      - "Security vulnerability assessment"
    tools: ["Bash", "playwright", "sequential"]
    outputs:
      - "Comprehensive quality report"
      - "Integration test results"
      - "Performance benchmarks"
      - "Security assessment report"
  
  documentation-finalization:
    tasks:
      - "Final documentation review and completion"
      - "API documentation generation and validation"
      - "User guide creation and review"
      - "Team knowledge transfer materials"
    outputs:
      - "Complete documentation suite"
      - "API documentation"
      - "User guides"
      - "Knowledge transfer materials"
```

#### Domain-Specific Enhancements
```yaml
frontend-implementation:
  persona-activation: "frontend"
  mcp-focus: "magic (UI components), context7 (patterns)"
  validation-focus: ["accessibility", "responsive-design", "performance", "user-experience"]
  documentation-types: ["component-docs", "style-guides", "user-guides"]

backend-implementation:
  persona-activation: "backend"
  mcp-focus: "context7 (patterns), sequential (architecture)"
  validation-focus: ["security", "performance", "scalability", "reliability"]
  documentation-types: ["api-docs", "architecture-docs", "deployment-guides"]

fullstack-implementation:
  persona-activation: ["frontend", "backend", "architect"]
  mcp-focus: "magic (UI), context7 (patterns), sequential (coordination)"
  validation-focus: ["integration", "end-to-end-testing", "performance", "user-experience"]
  documentation-types: ["system-docs", "api-docs", "user-guides", "deployment-guides"]
```

#### Quality Gates
- **Design Approval**: Architecture and design review completion
- **Implementation Review**: Code quality and best practice compliance
- **Testing Validation**: Test coverage and quality requirements met
- **Documentation Complete**: All documentation requirements satisfied
- **Integration Success**: Successful integration with existing systems

#### Usage Examples
```bash
# Frontend component implementation
/sc:bmad-implement "responsive user dashboard with real-time data" --domain frontend --best-practices --documentation-first

# Backend API with security focus
/sc:bmad-implement "user authentication API with JWT tokens" --domain backend --security-hardened --test-driven

# Full-stack feature with team coordination
/sc:bmad-implement "order processing system with payment integration" --domain fullstack --team-collaboration --compliance-check

# Performance-optimized implementation
/sc:bmad-implement "data analytics dashboard with large datasets" --performance-optimized --architecture-review
```

---

### `/sc:bmad-validate`
**Comprehensive BMAD methodology compliance validation**

#### Command Definition
```yaml
---
command: "/sc:bmad-validate"
category: "Quality & Validation"
purpose: "Multi-agent BMAD methodology compliance validation with detailed reporting"
wave-enabled: true
performance-profile: "complex"
persona-activation: ["qa", "security", "architect", "analyzer", "performance"]
mcp-integration: ["bmad-docs", "sequential", "playwright", "context7"]
---
```

#### Syntax
```bash
/sc:bmad-validate [target] [flags]
```

#### Parameters
```yaml
target:
  options: ["project", "module", "component", "feature", "documentation", "architecture", "processes"]
  default: "project"
  description: "Validation target and scope"

flags:
  --validation-type: "Type of validation [compliance|quality|security|performance|documentation|all]"
  --standards: "Validation standards [bmad|industry|custom|all]"
  --depth: "Validation depth [basic|standard|comprehensive|audit]"
  --output-format: "Report format [markdown|html|pdf|json|dashboard]"
  --continuous: "Enable continuous validation monitoring"
  --fix-suggestions: "Generate specific fix recommendations"
  --priority-ranking: "Rank issues by impact and effort"
  --team-report: "Generate team-specific validation reports"
  --compliance-certification: "Generate compliance certification report"
```

#### Validation Framework
```yaml
bmad-compliance-validation:
  best-practices-compliance:
    code-standards:
      validation-rules: ["naming-conventions", "code-organization", "commenting-standards"]
      quality-metrics: ["complexity-thresholds", "maintainability-index", "technical-debt-ratio"]
      pattern-compliance: ["design-patterns", "architectural-patterns", "security-patterns"]
    
    security-compliance:
      vulnerability-assessment: ["static-analysis", "dependency-vulnerabilities", "configuration-security"]
      security-patterns: ["authentication-patterns", "authorization-patterns", "data-protection"]
      compliance-standards: ["owasp-compliance", "security-framework-adherence"]
  
  methodology-compliance:
    process-adherence:
      development-process: ["workflow-compliance", "review-process", "testing-requirements"]
      documentation-process: ["documentation-coverage", "update-frequency", "review-process"]
      quality-gates: ["gate-compliance", "validation-completeness", "approval-process"]
    
    tool-integration:
      development-tools: ["configuration-standards", "automation-compliance", "integration-quality"]
      collaboration-tools: ["usage-patterns", "process-integration", "team-coordination"]
  
  architecture-compliance:
    design-principles:
      solid-principles: ["single-responsibility", "open-closed", "liskov-substitution", "interface-segregation", "dependency-inversion"]
      architectural-patterns: ["pattern-implementation", "pattern-consistency", "pattern-appropriateness"]
      decision-documentation: ["adr-completeness", "decision-rationale", "impact-assessment"]
    
    quality-attributes:
      scalability: ["horizontal-scaling-readiness", "vertical-scaling-optimization", "performance-patterns"]
      maintainability: ["code-organization", "documentation-quality", "change-impact-assessment"]
      reliability: ["error-handling", "fault-tolerance", "monitoring-integration"]
  
  documentation-compliance:
    coverage-requirements:
      technical-documentation: ["api-documentation", "architecture-documentation", "deployment-documentation"]
      user-documentation: ["user-guides", "tutorials", "troubleshooting-documentation"]
      process-documentation: ["development-processes", "operational-procedures", "team-guidelines"]
    
    quality-standards:
      accuracy: ["technical-accuracy", "currency", "completeness"]
      accessibility: ["readability", "searchability", "multi-format-support"]
      maintenance: ["update-automation", "review-process", "version-control"]
```

#### Multi-Agent Validation Workflow
```yaml
wave-1-scope-analysis:
  scope-definition:
    tasks:
      - "Validation scope analysis and boundary definition"
      - "Standards and criteria identification"
      - "Resource requirement estimation"
      - "Validation strategy customization"
    agents: ["analyzer", "architect"]
    outputs: ["validation-scope", "criteria-matrix", "strategy-plan"]

wave-2-parallel-validation:
  quality-validation:
    agent: "qa"
    focus: ["code-quality", "testing-coverage", "process-compliance"]
    tools: ["Grep", "Read", "Bash", "playwright"]
  
  security-validation:
    agent: "security"
    focus: ["vulnerability-assessment", "security-patterns", "compliance-standards"]
    tools: ["Grep", "Bash", "context7", "bmad-docs"]
  
  architecture-validation:
    agent: "architect"
    focus: ["design-principles", "architectural-patterns", "decision-documentation"]
    tools: ["Read", "Grep", "sequential", "bmad-docs"]
  
  performance-validation:
    agent: "performance"
    focus: ["performance-patterns", "scalability-assessment", "optimization-compliance"]
    tools: ["Bash", "playwright", "context7"]

wave-3-synthesis-and-prioritization:
  validation-synthesis:
    tasks:
      - "Multi-agent validation result synthesis"
      - "Cross-validation consistency checking"
      - "Issue prioritization and impact assessment"
      - "Fix recommendation generation"
    agent: "analyzer"
    tools: ["sequential", "Write"]
    outputs: ["synthesis-report", "prioritized-issues", "fix-recommendations"]

wave-4-reporting-and-certification:
  comprehensive-reporting:
    tasks:
      - "Comprehensive validation report generation"
      - "Team-specific report customization"
      - "Compliance certification preparation"
      - "Continuous monitoring setup"
    agent: "qa"
    tools: ["Write", "bmad-docs"]
    outputs: ["validation-report", "team-reports", "certification", "monitoring-setup"]
```

#### Quality Gates
- **Validation Completeness**: All specified validation dimensions covered
- **Multi-Agent Consistency**: Consistent validation results across agents
- **Priority Accuracy**: Accurate prioritization of issues and recommendations
- **Actionability**: Specific, implementable fix recommendations

#### Usage Examples
```bash
# Comprehensive project validation
/sc:bmad-validate project --validation-type all --depth comprehensive --fix-suggestions

# Security-focused validation with certification
/sc:bmad-validate --validation-type security --standards all --compliance-certification

# Continuous quality monitoring setup
/sc:bmad-validate module --continuous --priority-ranking --team-report

# Architecture compliance audit
/sc:bmad-validate architecture --depth audit --standards bmad --output-format dashboard
```

---

### `/sc:bmad-document`
**BMAD-compliant documentation generation and management**

#### Command Definition
```yaml
---
command: "/sc:bmad-document"
category: "Documentation & Knowledge Management"
purpose: "Generate and maintain BMAD-compliant documentation with automation"
wave-enabled: true
performance-profile: "standard"
persona-activation: ["scribe", "architect", "mentor"]
mcp-integration: ["bmad-docs", "context7", "sequential"]
---
```

#### Syntax
```bash
/sc:bmad-document [scope] [flags]
```

#### Parameters
```yaml
scope:
  options: ["project", "api", "architecture", "user-guide", "deployment", "processes", "onboarding"]
  default: "project"
  description: "Documentation scope and type"

flags:
  --format: "Output format [markdown|html|pdf|docx|confluence|notion]"
  --template: "Documentation template [bmad-standard|custom|minimal|comprehensive]"
  --auto-generate: "Auto-generate from code annotations and comments"
  --interactive: "Interactive documentation creation with guided prompts"
  --multi-language: "Generate documentation in multiple languages"
  --live-sync: "Enable live synchronization with code changes"
  --quality-check: "Perform documentation quality assessment"
  --accessibility: "Ensure accessibility compliance in documentation"
  --version-control: "Enable documentation version control integration"
  --team-collaboration: "Enable collaborative documentation features"
```

#### Documentation Types and Templates
```yaml
project-documentation:
  overview:
    sections: ["project-purpose", "architecture-overview", "technology-stack", "team-structure"]
    auto-generation: ["repository-analysis", "dependency-extraction", "team-detection"]
  
  setup-and-installation:
    sections: ["prerequisites", "installation-steps", "configuration", "verification"]
    auto-generation: ["package-manager-detection", "build-script-analysis", "environment-variables"]
  
  development-guide:
    sections: ["development-workflow", "coding-standards", "testing-procedures", "deployment-process"]
    auto-generation: ["workflow-analysis", "standard-extraction", "test-framework-detection"]

api-documentation:
  endpoint-documentation:
    auto-generation: ["openapi-spec-generation", "request-response-examples", "error-code-documentation"]
    validation: ["endpoint-existence-verification", "schema-consistency-check", "example-accuracy-validation"]
  
  integration-guides:
    sections: ["authentication", "rate-limiting", "error-handling", "sdk-examples"]
    auto-generation: ["auth-pattern-detection", "rate-limit-extraction", "error-pattern-analysis"]

architecture-documentation:
  system-design:
    sections: ["system-overview", "component-architecture", "data-flow", "integration-patterns"]
    auto-generation: ["dependency-graph-generation", "service-interaction-mapping", "data-flow-analysis"]
  
  decision-records:
    auto-generation: ["adr-template-application", "decision-context-extraction", "rationale-documentation"]
    validation: ["decision-consistency-check", "impact-assessment-validation", "update-frequency-monitoring"]

user-guide-documentation:
  user-workflows:
    sections: ["getting-started", "common-tasks", "advanced-features", "troubleshooting"]
    auto-generation: ["feature-detection", "workflow-analysis", "error-scenario-identification"]
  
  tutorial-content:
    sections: ["step-by-step-tutorials", "interactive-examples", "video-content-scripts"]
    validation: ["tutorial-accuracy-testing", "example-execution-verification", "accessibility-compliance-check"]

deployment-documentation:
  deployment-procedures:
    sections: ["environment-setup", "deployment-steps", "monitoring-configuration", "rollback-procedures"]
    auto-generation: ["deployment-script-analysis", "infrastructure-as-code-extraction", "monitoring-setup-detection"]
  
  operational-guides:
    sections: ["maintenance-procedures", "troubleshooting-guides", "performance-monitoring", "security-procedures"]
    auto-generation: ["log-analysis-patterns", "metric-extraction", "alert-configuration-documentation"]
```

#### Documentation Generation Workflow
```yaml
wave-1-analysis-and-planning:
  content-analysis:
    tasks:
      - "Existing documentation audit and gap analysis"
      - "Code annotation and comment extraction"
      - "Configuration and setup procedure analysis"
      - "Team process and workflow documentation needs assessment"
    tools: ["Read", "Grep", "Glob", "bmad-docs"]
    outputs: ["content-inventory", "gap-analysis", "generation-plan"]

wave-2-automated-generation:
  content-generation:
    tasks:
      - "Auto-generation from code analysis and annotations"
      - "Template application with BMAD compliance"
      - "Cross-reference and link generation"
      - "Diagram and visual content creation"
    tools: ["context7", "bmad-docs", "Write", "sequential"]
    outputs: ["draft-documentation", "visual-content", "cross-reference-map"]

wave-3-quality-and-validation:
  quality-assurance:
    tasks:
      - "Documentation accuracy verification"
      - "Accessibility compliance checking"
      - "Cross-reference validation"
      - "Multi-format consistency verification"
    tools: ["sequential", "Read", "bmad-docs"]
    outputs: ["quality-report", "accessibility-assessment", "consistency-verification"]

wave-4-publishing-and-maintenance:
  publishing-setup:
    tasks:
      - "Multi-format export and publishing"
      - "Live synchronization configuration"
      - "Version control integration setup"
      - "Collaborative editing and review workflow setup"
    tools: ["Write", "Bash", "context7"]
    outputs: ["published-documentation", "sync-configuration", "collaboration-setup"]
```

#### Quality Standards and Validation
```yaml
documentation-quality-standards:
  content-quality:
    accuracy: ["technical-accuracy-verification", "code-example-testing", "link-validation"]
    completeness: ["coverage-assessment", "gap-identification", "missing-content-detection"]
    clarity: ["readability-analysis", "language-complexity-assessment", "structure-evaluation"]
  
  accessibility-compliance:
    visual-accessibility: ["color-contrast-checking", "font-size-compliance", "visual-hierarchy-validation"]
    content-accessibility: ["alt-text-verification", "heading-structure-validation", "semantic-markup-checking"]
    navigation-accessibility: ["keyboard-navigation", "screen-reader-compatibility", "search-functionality"]
  
  maintenance-requirements:
    currency: ["update-frequency-monitoring", "change-detection-automation", "obsolescence-identification"]
    consistency: ["style-guide-compliance", "terminology-consistency", "format-standardization"]
    integration: ["version-control-synchronization", "automated-update-workflows", "collaborative-review-processes"]
```

#### Usage Examples
```bash
# Comprehensive project documentation generation
/sc:bmad-document project --auto-generate --quality-check --multi-language

# Interactive API documentation creation
/sc:bmad-document api --interactive --live-sync --format html

# Architecture documentation with BMAD compliance
/sc:bmad-document architecture --template bmad-standard --version-control

# User guide with accessibility compliance
/sc:bmad-document user-guide --accessibility --format pdf --team-collaboration
```

---

## 🔗 Integration Commands

### `/sc:bmad-build`
**Enhanced build process with BMAD methodology validation**

#### Command Definition
```yaml
---
command: "/sc:bmad-build"
category: "Development & Deployment"
purpose: "BMAD-enhanced build process with quality gates and documentation updates"
wave-enabled: true
performance-profile: "optimization"
persona-activation: ["intelligent-domain-detection", "qa", "performance"]
mcp-integration: ["bmad-docs", "context7", "sequential"]
---
```

#### Enhanced Build Pipeline
```yaml
pre-build-validation:
  bmad-compliance-check:
    - "Methodology adherence validation"
    - "Best practice compliance verification"
    - "Documentation currency check"
  
  quality-gates:
    - "Code quality threshold validation"
    - "Security vulnerability assessment"
    - "Test coverage requirement verification"

build-process-enhancement:
  automated-documentation-update:
    - "API documentation regeneration"
    - "Architecture diagram updates" 
    - "Deployment guide synchronization"
  
  quality-metrics-collection:
    - "Build performance metrics"
    - "Code quality trend analysis"
    - "Methodology compliance scoring"

post-build-validation:
  comprehensive-testing:
    - "Unit test execution with coverage analysis"
    - "Integration test validation"
    - "Performance benchmark comparison"
  
  deployment-readiness:
    - "Deployment checklist validation"
    - "Environment configuration verification"
    - "Rollback procedure preparation"
```

### `/sc:bmad-deploy`
**Deployment with BMAD operational excellence**

#### Command Definition
```yaml
---
command: "/sc:bmad-deploy"
category: "Deployment & Operations"
purpose: "BMAD-compliant deployment with operational documentation and monitoring"
wave-enabled: true
performance-profile: "optimization"
persona-activation: ["devops", "security", "qa"]
mcp-integration: ["bmad-docs", "sequential", "context7"]
---
```

### `/sc:bmad-review`
**Comprehensive BMAD methodology review and assessment**

#### Command Definition
```yaml
---
command: "/sc:bmad-review"
category: "Quality & Review"
purpose: "Multi-agent BMAD methodology review with team learning integration"
wave-enabled: true
performance-profile: "complex"
persona-activation: ["analyzer", "architect", "mentor", "qa"]
mcp-integration: ["bmad-docs", "sequential", "context7"]
---
```

---

## 🎯 Command Integration Matrix

### SuperClaude Command Enhancement
```yaml
existing-command-enhancement:
  /sc:build:
    bmad-flags: ["--bmad-validate", "--methodology-compliance", "--documentation-update"]
    auto-activation: "complexity > 0.7 OR team-size > 5"
  
  /sc:implement:
    bmad-flags: ["--bmad-guided", "--best-practices", "--methodology-validation"]
    auto-activation: "enterprise-project OR critical-feature"
  
  /sc:analyze:
    bmad-flags: ["--bmad-standards", "--methodology-assessment", "--improvement-roadmap"]
    auto-activation: "comprehensive-analysis OR methodology-keywords-detected"
  
  /sc:swarm:
    bmad-enhancement: "BMAD methodology agent coordination"
    specialized-agents: ["bmad-architect", "bmad-validator", "bmad-documenter"]
  
  /sc:hive-mind:
    bmad-integration: "BMAD consensus validation for architectural decisions"
    collective-intelligence: "Methodology best practice evolution through consensus"
```

### Flag-Based Integration
```yaml
universal-bmad-flags:
  --bmad-guided: "Enable step-by-step BMAD methodology guidance for any command"
  --bmad-validate: "Add BMAD compliance validation to any command execution"
  --methodology-check: "Real-time best practice validation during command execution"
  --bmad-document: "Auto-generate BMAD-compliant documentation for command outputs"
  --best-practices: "Apply domain-specific best practices to any command"
  --compliance-report: "Generate compliance report for any command execution"
```

---

This comprehensive command specification provides the technical foundation for implementing BMAD-METHOD integration within The Hive's SuperClaude framework. Each command is designed to work seamlessly with existing SuperClaude capabilities while providing systematic methodology enhancement and validation.
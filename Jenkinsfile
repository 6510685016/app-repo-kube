pipeline {
    agent any

    environment {
        TAG = "${BUILD_NUMBER}"

        NEXUS_REGISTRY = "192.168.11.128:8082"
        NEXUS_REPO     = "docker-hosted"
        BACKEND_IMAGE  = "kube-gitops-backend"

        HELM_RELEASE   = "gitops-backend"
        HELM_CHART     = "./helm/gitops-backend"
        K8S_NAMESPACE  = "default"

        KUBECONFIG     = "/home/jenkins/.kube/config"
    }

    triggers {
        githubPush()
    }

    stages {

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                    cd backend
                    chmod +x mvnw
                    ./mvnw clean verify sonar:sonar \
                      -Dsonar.projectKey=kube-gitops-backend \
                      -Dsonar.host.url=http://192.168.11.128:9000 \
                      -Dsonar.login=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    echo "$NEXUS_PASS" | docker login ${NEXUS_REGISTRY} \
                      -u "$NEXUS_USER" --password-stdin

                    docker build --no-cache \
                      -t ${NEXUS_REGISTRY}/${NEXUS_REPO}/${BACKEND_IMAGE}:${TAG} \
                      backend

                    docker push ${NEXUS_REGISTRY}/${NEXUS_REPO}/${BACKEND_IMAGE}:${TAG}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            environment {
                KUBECONFIG = '/kubeconfig'
            }
            steps {
                sh '''
                set -e

                echo "🚀 Deploy Spring Boot Backend to Kubernetes"

                # show nodes
                kubectl get nodes

                # create namespace if not exists
                kubectl get namespace ${K8S_NAMESPACE} >/dev/null 2>&1 || \
                kubectl create namespace ${K8S_NAMESPACE}

                # install or upgrade helm chart
                helm upgrade --install ${HELM_RELEASE} ${HELM_CHART} \
                --namespace ${K8S_NAMESPACE} \
                --set image.repository=${NEXUS_REGISTRY}/${NEXUS_REPO}/${BACKEND_IMAGE} \
                --set image.tag=${TAG} \
                --wait \
                --timeout 10m

                kubectl get endpoints gitops-backend
                kubectl describe ing gitops-backend
                kubectl get pods -o wide

                echo "✅ Helm deploy finished"
                '''
            }
        }


        stage('Verify') {
            environment {
                KUBECONFIG = '/kubeconfig'
            }
            steps {
                script {
                    try {
                        sh '''
                        echo "🩺 Wait for Spring Boot healthcheck..."

                        sleep 15

                        for i in $(seq 1 10); do
                          echo "Healthcheck attempt $i..."

                          if curl -f http://192.168.11.129:30080/actuator/health; then
                            echo "✅ Healthcheck VM2 passed"
                            
                            if curl -f http://192.168.11.130:30080/actuator/health; then
                                echo "✅ Healthcheck VM3 passed"
                                exit 0
                            fi
                          fi

                          sleep 5
                        done

                        echo "❌ Healthcheck failed"
                        exit 1
                        '''
                    } catch (err) {
                        echo "❌ Deploy failed → Rollback"

                        currentBuild.result = 'FAILURE'
                        throw err
                    }
                }
            }
        }
    }
}
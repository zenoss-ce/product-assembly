#!/usr/bin/env groovy

node {

  def build_number = 'ce-5.3'
  def maturity = '0'
  stage('Checkout') {
    checkout scm
  }

  stage('Build product base image') {
    sh """
      cd product-base && \
      make clean V=1 BUILD_NUMBER=${build_number} MATURITY=${maturity} && \
      make build V=1 BUILD_NUMBER=${build_number} MATURITY=${maturity}
    """
  }

  stage('Build product core image') {
    sh """
      cd core && \
      make clean V=1 BUILD_NUMBER=${build_number} MATURITY=${maturity} && \
      make build V=1 BUILD_NUMBER=${build_number} MATURITY=${maturity}
    """
  }

  stage('Publish product core image') {
    withDockerRegistry([ credentialsId: "dockerhub-zenoss-ce", url: "" ]) {
    sh """
      cd core && \
      make push V=1 BUILD_NUMBER=${build_number} MATURITY=${maturity}
    """
    }
  }

}

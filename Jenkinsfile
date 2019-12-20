#!groovy

@Library('cdis-jenkins-lib@fix/docker') _

testPipeline {
  quayRegistry = "nginx"
  serviceTesting = [name: "revproxy"]
}

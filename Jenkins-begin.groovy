node{
    PRODUCT_BUILD_NUMBER=env.BUILD_NUMBER
    currentBuild.displayName = "product bld #${PRODUCT_BUILD_NUMBER}"

    stage 'Checkout product-assembly repo'
        // FIXME: parameterize the git credentialsID
        sshagent(['6ece10bd-11c1-4e23-8f36-6848f6c4c704']) {
            sh("git rev-parse HEAD >git_sha.id")
            git_sha=readFile('git_sha.id').trim()
            println("Got sha='#${git_sha}'")
        }

    stage 'Build product-base'
        sh("MATURITY=${MATURITY} BUILD_NUMBER=${PRODUCT_BUILD_NUMBER} make clean build")

    stage 'Build All Products'
        def branches = [
            'core': {
                println "Starting core-pipeline with parameters #${MATURITY} #${PRODUCT_BUILD_NUMBER}"
                build job: 'core-pipeline', parameters: [
                    [$class: 'ChoiceParameterValue', name: 'MATURITY', value: MATURITY],
                    [$class: 'StringParameterValue', name: 'PRODUCT_BUILD_NUMBER', value: PRODUCT_BUILD_NUMBER],
                ]
            },
            'resmgr': {
                println "Starting resmgr-pipeline with parameters #${MATURITY} #${PRODUCT_BUILD_NUMBER}"
                build job: 'resmgr-pipeline', parameters: [
                    [$class: 'ChoiceParameterValue', name: 'MATURITY', value: MATURITY],
                    [$class: 'StringParameterValue', name: 'PRODUCT_BUILD_NUMBER', value: PRODUCT_BUILD_NUMBER],
                ]
            },
        ]

        parallel branches
}

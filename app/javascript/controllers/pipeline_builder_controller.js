import { Controller } from "@hotwired/stimulus"
import React from 'react'
import { createRoot } from 'react-dom/client'
import PipelineBuilder from '../components/PipelineBuilder'

// Connects to data-controller="pipeline-builder"
export default class extends Controller {
  static values = {
    pipelineId: String,
    pipelineName: String
  }

  connect() {
    // Create a root for the React component
    const root = createRoot(this.element)

    // Render the PipelineBuilder component
    root.render(
      React.createElement(PipelineBuilder, {
        pipelineId: this.pipelineIdValue,
        pipelineName: this.pipelineNameValue
      })
    )

    // Store the root for cleanup
    this.reactRoot = root
  }

  disconnect() {
    // Clean up the React component when the Stimulus controller disconnects
    if (this.reactRoot) {
      this.reactRoot.unmount()
    }
  }
}
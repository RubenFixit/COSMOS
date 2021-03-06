<!--
# Copyright 2021 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder
-->

<template>
  <v-row justify="center">
    <v-dialog v-model="show" @keydown.esc="show = false" width="300">
      <v-card>
        <v-card-title>Open Configuration</v-card-title>
        <v-card-text>
          <v-list>
            <v-subheader>Existing Configurations</v-subheader>
            <v-list-item-group v-model="configIndex" color="primary">
              <v-list-item v-for="(config, i) in configs" :key="i">
                <v-list-item-content>
                  <v-list-item-title v-text="config"></v-list-item-title>
                </v-list-item-content>
                <v-list-item-icon>
                  <v-icon @click="deleteConfig(config)">mdi-delete</v-icon>
                </v-list-item-icon>
              </v-list-item>
            </v-list-item-group>
          </v-list>
          <v-alert dense type="warning" v-if="warning"
            >Select a configuration</v-alert
          >
        </v-card-text>
        <v-card-actions>
          <v-btn color="primary" text @click="success()">Ok</v-btn>
          <v-spacer></v-spacer>
          <v-btn color="primary" text @click="show = false">Cancel</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-row>
</template>

<script>
import { CosmosApi } from '../services/cosmos-api'

export default {
  props: {
    tool: String,
    value: Boolean, // value is the default prop when using v-model
  },
  data() {
    return {
      api: null,
      configIndex: null,
      configs: [],
      warning: false,
    }
  },
  computed: {
    show: {
      get() {
        return this.value
      },
      set(value) {
        this.$emit('input', value) // input is the default event when using v-model
      },
    },
  },
  created() {
    this.api = new CosmosApi()
  },
  async mounted() {
    this.configs = await this.api.list_configs(this.tool)
  },
  methods: {
    success() {
      if (this.configIndex === null) {
        this.warning = true
        return
      }
      this.warning = false
      this.show = false
      this.$emit('success', this.configs[this.configIndex])
    },
    deleteConfig(config) {
      this.configs.splice(this.configs.indexOf(config), 1)
      this.api.delete_config(this.tool, config)
    },
  },
}
</script>

<style scoped>
.theme--dark .v-card__title,
.theme--dark .v-card__subtitle {
  background-color: var(--v-secondary-darken3);
}
</style>

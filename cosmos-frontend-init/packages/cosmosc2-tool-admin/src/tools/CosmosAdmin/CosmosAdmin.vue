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
  <div>
    <TopBar :title="title" />

    <v-card>
      <v-tabs v-model="curTab" fixed-tabs>
        <v-tab v-for="(tab, index) in tabs" :key="index" :to="tab.url">{{
          tab.name
        }}</v-tab>
      </v-tabs>
      <router-view />
    </v-card>
  </div>
</template>

<script>
import TopBar from '@cosmosc2/tool-common/src/components/TopBar'
export default {
  components: {
    TopBar,
  },
  data() {
    return {
      title: 'COSMOS Administrator Console',
      curTab: null,
      tabs: [
        { name: 'Plugins', component: 'PluginsTab', url: '/plugins' },
        { name: 'Targets', component: 'TargetsTab', url: '/targets' },
        {
          name: 'Interfaces',
          component: 'InterfacesTab',
          url: '/interfaces',
        },
        { name: 'Routers', component: 'RoutersTab', url: '/routers' },
        {
          name: 'Microservices',
          component: 'MicroservicesTab',
          url: '/microservices',
        },
        { name: 'Tools', component: 'ToolsTab', url: '/tools' },
        { name: 'Gems', component: 'GemsTab', url: '/gems' },
        { name: 'Scopes', component: 'ScopesTab', url: '/scopes' },
        { name: 'Settings', component: 'SettingsTab', url: '/settings' },
      ],
    }
  },
  methods: {},
}
</script>

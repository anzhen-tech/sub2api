<template>
  <div class="card overflow-hidden">
    <!-- Toggle Button -->
    <button
      @click="toggleExpanded"
      class="flex w-full items-center justify-between px-6 py-3 text-left transition-colors hover:bg-gray-50 dark:hover:bg-dark-700"
    >
      <span class="text-sm font-semibold text-gray-900 dark:text-white">
        {{ t('usage.charts.title') }}
      </span>
      <svg
        class="h-5 w-5 text-gray-500 transition-transform duration-200 dark:text-gray-400"
        :class="{ 'rotate-180': expanded }"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Charts Grid -->
    <transition
      enter-active-class="transition-all duration-300 ease-out"
      leave-active-class="transition-all duration-200 ease-in"
      enter-from-class="max-h-0 opacity-0"
      enter-to-class="max-h-[1000px] opacity-100"
      leave-from-class="max-h-[1000px] opacity-100"
      leave-to-class="max-h-0 opacity-0"
    >
      <div v-show="expanded" class="overflow-hidden border-t border-gray-200 dark:border-dark-700">
        <!-- Granularity Selector -->
        <div class="flex items-center gap-2 px-4 pt-4">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">
            {{ t('usage.charts.granularity') }}:
          </span>
          <div class="inline-flex rounded-lg border border-gray-200 dark:border-dark-600">
            <button
              v-for="option in granularityOptions"
              :key="option.value"
              @click="onGranularityChange(option.value)"
              class="px-3 py-1 text-xs font-medium transition-colors first:rounded-l-lg last:rounded-r-lg"
              :class="
                granularity === option.value
                  ? 'bg-blue-500 text-white'
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-dark-600'
              "
            >
              {{ option.label }}
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 p-4 lg:grid-cols-2">
          <ApiKeyTrendChart
            :trends="apiKeyTrends"
            metric="requests"
            :title="t('usage.charts.requestsTrend')"
            :loading="loading"
          />
          <ApiKeyTrendChart
            :trends="apiKeyTrends"
            metric="total_tokens"
            :title="t('usage.charts.tokenUsageTrend')"
            :loading="loading"
          />
          <ApiKeyTrendChart
            :trends="apiKeyTrends"
            metric="actual_cost"
            :title="t('usage.charts.costTrend')"
            :loading="loading"
          />
          <ApiKeyModelDistribution :distribution="modelDistribution" :loading="loading" />
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import ApiKeyTrendChart from '@/components/charts/ApiKeyTrendChart.vue'
import ApiKeyModelDistribution from '@/components/charts/ApiKeyModelDistribution.vue'
import type { APIKeyTrendItem, APIKeyModelDistributionItem } from '@/api/usage'

const { t } = useI18n()

const STORAGE_KEY = 'usage-charts-expanded'

defineProps<{
  apiKeyTrends: APIKeyTrendItem[]
  modelDistribution: APIKeyModelDistributionItem[]
  loading?: boolean
  granularity: string
}>()

const emit = defineEmits<{
  'update:granularity': [value: string]
}>()

const granularityOptions = computed(() => [
  { value: 'hour', label: t('usage.charts.granularityHour') },
  { value: 'day', label: t('usage.charts.granularityDay') },
  { value: 'month', label: t('usage.charts.granularityMonth') }
])

const onGranularityChange = (value: string) => {
  emit('update:granularity', value)
}

const expanded = ref(false)

const toggleExpanded = () => {
  expanded.value = !expanded.value
  localStorage.setItem(STORAGE_KEY, String(expanded.value))
}

onMounted(() => {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored === 'true') {
    expanded.value = true
  }
})
</script>

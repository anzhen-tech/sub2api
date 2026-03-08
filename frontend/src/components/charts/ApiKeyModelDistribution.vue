<template>
  <div class="card p-4">
    <h3 class="mb-4 text-sm font-semibold text-gray-900 dark:text-white">
      {{ t('usage.charts.apiKeyModelDistribution') }}
    </h3>
    <div v-if="loading" class="flex h-48 items-center justify-center">
      <LoadingSpinner />
    </div>
    <div v-else-if="distribution.length > 0 && chartData" class="h-48">
      <Bar :data="chartData" :options="barOptions" />
    </div>
    <div
      v-else
      class="flex h-48 items-center justify-center text-sm text-gray-500 dark:text-gray-400"
    >
      {{ t('usage.charts.noData') }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import { Bar } from 'vue-chartjs'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import type { APIKeyModelDistributionItem } from '@/api/usage'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const { t } = useI18n()

const props = defineProps<{
  distribution: APIKeyModelDistributionItem[]
  loading?: boolean
}>()

const PRESET_COLORS = [
  '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6',
  '#06b6d4', '#ec4899', '#f97316', '#14b8a6', '#6366f1',
  '#84cc16', '#a855f7', '#0ea5e9', '#d946ef', '#22c55e'
]

const isDarkMode = computed(() => {
  return document.documentElement.classList.contains('dark')
})

const chartColors = computed(() => ({
  text: isDarkMode.value ? '#e5e7eb' : '#374151',
  grid: isDarkMode.value ? '#374151' : '#e5e7eb'
}))

// Collect all unique models, sorted by total requests descending
const allModels = computed(() => {
  const modelMap = new Map<string, number>()
  for (const item of props.distribution) {
    for (const m of item.models) {
      modelMap.set(m.model, (modelMap.get(m.model) || 0) + m.requests)
    }
  }
  return Array.from(modelMap.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([name]) => name)
})

// Per-API-Key total requests for percentage calculation
const apiKeyTotals = computed(() =>
  props.distribution.map((item) =>
    item.models.reduce((sum, m) => sum + m.requests, 0)
  )
)

// Build raw data lookup: distribution[keyIdx].models -> { model -> data }
const rawDataLookup = computed(() =>
  props.distribution.map((item) => {
    const map = new Map<string, typeof item.models[number]>()
    for (const m of item.models) {
      map.set(m.model, m)
    }
    return map
  })
)

const chartData = computed(() => {
  if (!props.distribution?.length) return null

  // Y-axis labels: API Key names
  const labels = props.distribution.map(
    (item) => item.api_key_name || `Key #${item.api_key_id}`
  )

  // One dataset per model, data is percentage of that model in each API Key
  const datasets = allModels.value.map((modelName, index) => {
    const color = PRESET_COLORS[index % PRESET_COLORS.length]
    const data = props.distribution.map((item, keyIdx) => {
      const found = item.models.find((m) => m.model === modelName)
      const total = apiKeyTotals.value[keyIdx]
      if (!found || total === 0) return 0
      return parseFloat(((found.requests / total) * 100).toFixed(1))
    })

    return {
      label: modelName,
      data,
      backgroundColor: color,
      borderWidth: 0,
      borderSkipped: false as const
    }
  })

  return { labels, datasets }
})

const barOptions = computed(() => ({
  indexAxis: 'y' as const,
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    intersect: false,
    mode: 'index' as const
  },
  plugins: {
    legend: {
      position: 'top' as const,
      labels: {
        color: chartColors.value.text,
        usePointStyle: true,
        pointStyle: 'rect',
        padding: 12,
        font: { size: 10 }
      }
    },
    tooltip: {
      callbacks: {
        title: (items: any[]) => {
          if (!items.length) return ''
          const keyIdx = items[0].dataIndex
          const keyName = props.distribution[keyIdx]?.api_key_name || `Key #${props.distribution[keyIdx]?.api_key_id}`
          const total = apiKeyTotals.value[keyIdx]
          return `${keyName} (${total.toLocaleString()} ${t('usage.charts.requests')})`
        },
        label: (context: any) => {
          const keyIdx = context.dataIndex
          const modelName = context.dataset.label
          const lookup = rawDataLookup.value[keyIdx]
          const modelData = lookup?.get(modelName)
          if (!modelData) return ''
          const pct = context.raw
          return `${modelName}: ${modelData.requests.toLocaleString()} (${pct}%) · $${formatCost(modelData.actual_cost)}`
        }
      }
    }
  },
  scales: {
    x: {
      stacked: true,
      max: 100,
      grid: { color: chartColors.value.grid },
      ticks: {
        color: chartColors.value.text,
        font: { size: 10 },
        callback: (value: string | number) => `${value}%`
      }
    },
    y: {
      stacked: true,
      grid: { display: false },
      ticks: {
        color: chartColors.value.text,
        font: { size: 10 }
      }
    }
  }
}))

const formatCost = (value: number): string => {
  if (value >= 1000) return (value / 1000).toFixed(2) + 'K'
  if (value >= 1) return value.toFixed(2)
  if (value >= 0.01) return value.toFixed(3)
  return value.toFixed(4)
}
</script>

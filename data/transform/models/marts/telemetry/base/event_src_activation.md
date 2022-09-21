{% docs event_src_activation %}

Our telemetry events were originally coming from Google Analytics in structured form, then we started using Snowplow continuing to send the same structured events, then we upgraded to send rich unstructured events to Snowplow along with the structured events, then we ultimately turned off the structured events in favor of the unstructured events.

1. Google Analytics structured
1. Snowplow structured
1. Snowplow structured and unstructured (>=2.0)
1. Snowplow unstructured (>=2.5.0)

Since we have these 4 states we need to blend them carefully to preserve history and to transition from one source/structure to the next in an accurate way.

This model does its best to define when Snowplow should be activated as the primary telemetry source for a project.
The challenge is that we don't want to flip to the new source immediately upon recieving the first event from that source/structure.
For example some projects will be running in production with GA as the source but they test >2.0 version locally. We still want to consider GA as the primary source until we get more events coming from Snowplow than from GA. This model compares event counts to decide what date we have enough Snowplow events to get full coverage on the project's activity before activating it.

Snowplow receives more events that GA does because the GA only gets successful executions whereas Snowplow gets all executions. So the most accurate way to compare counts is to filter only when we got both an unstructured event and a structured event in parallel. Unfortunately that approach has many limitations: meltano version >=2.5.0 turns off sending parallel structured events, the presence of failure/aborted events means some projects never send a successful structured event but they do send failed/aborted unstructured events, etc.

The decision was to reduce complexity with a small accuracy tradeoff by comparing all Snowplow event counts to GA event counts. Snowplow only receives about 5% more events than GA so its a worth while tradeoff.

{% enddocs %}
